<script>
	import { open } from '@tauri-apps/api/dialog';
	import { convertFileSrc } from '@tauri-apps/api/tauri';
	import { v4 as uuid_v4 } from 'uuid';

	let images_file_filter = {
		name: 'Images',
		extensions: ['png', 'jpg', 'jpeg', 'bmp']
	};

	let grid_cell_size = 40;

	let tilesets = [];

	// backgrounds is a list of images that are drawn behind the layers in the game.
	window.backgrounds = {
		paths: [],
		images: [],
		x: 0,
		y: 0,
	};

	// layers is a list of layers that are drawn in the game. Layer 0 is the active layer
	// that interacts with the player. Layers with a positive z-index are drawn on top of
	// the active layer, and layers with a negative z-index are drawn before the active
	// layer.
	window.layers = [];

	// camera is the position of the camera in the level editor.
	window.camera = {
		x: 0,
		y: 0,
		zoom: 1
	};

	// Helps to pan the camera by keeping track of the mouse position
	// and whether or not the mouse is down.
	window.mouse = {
		x: {
			end: 0,
			start: 0
		},
		y: {
			end: 0,
			start: 0
		},
		is_down: false
	};

	// onreadystatechange == 'complete' is the same as $(document).ready() in jQuery.
	document.onreadystatechange = function () {
		if (document.readyState === 'complete') {
			// Opens and closes the sidebar.
			let sidebar = document.querySelector('div#sidebar-container');
			let openSidebarBttn = document.querySelector('div#sidebar-opener');
			openSidebarBttn.addEventListener('click', function() {
				sidebar.classList.toggle('sidebar-closed')
				openSidebarBttn.classList.toggle('sidebar-closed')
			})

			// Opens a native file dialog and adds the selected file(s) to the backgrounds list.
			let addBackgroundBttn = document.querySelector('div#addBackgroundBttn');
			addBackgroundBttn.addEventListener('click', async function() {
				await addBackground();
			});

			// Opens a dialog to add a new layer.
			let addLayerBttn = document.querySelector('div#addLayerBttn');
			addLayerBttn.addEventListener('click', function() {
				document.querySelector('div#addLayerDialog').classList.remove('hidden');
			});
			// Checks if the z-index input is valid.
			let addLayerDialogZIndex = document.querySelector('div#addLayerDialogZIndex > input');
			addLayerDialogZIndex.addEventListener('keyup', function() {
				addLayerDialogZIndexKeyUp(this);
			});
			// Checks if the layer name is valid.
			let addLayerDialogName = document.querySelector('div#addLayerDialogName > input');
			addLayerDialogName.addEventListener('keyup', function() {
				addLayerDialogNameKeyUp(this);
			});
			// Adds a layer to the layers list.
			let addLayerDialogAdd = document.querySelector('button#addLayerDialogAdd');
			addLayerDialogAdd.addEventListener('click', function() {
				let name = document.querySelector('div#addLayerDialogName > input').value;
				let z_index = parseInt(document.querySelector('div#addLayerDialogZIndex > input').value);
				if (addLayerDialogNameKeyUp(addLayerDialogName) && addLayerDialogZIndexKeyUp(addLayerDialogZIndex)) {
					addLayer(name, z_index);
					document.querySelector('div#addLayerDialog').classList.add('hidden');
					return true;
				}
				return false;
			});
			// Closes the add layer dialog.
			let addLayerDialogCancel = document.querySelector('button#addLayerDialogCancel');
			addLayerDialogCancel.addEventListener('click', function() {
				document.querySelector('div#addLayerDialog').classList.add('hidden');
			});

			// Opens a dialog to add a new tileset.
			let addTilesetBttn = document.querySelector('div#addTilesetBttn');
			addTilesetBttn.addEventListener('click', function() {
				document.querySelector('div#addTilesetDialog').classList.remove('hidden');
			});
			// Checks if the tile size input is valid.
			let addTilesetDialogTileSize = document.querySelectorAll('div#addTilesetDialogTileSize > input');
			addTilesetDialogTileSize.forEach(function(elem) {
				elem.addEventListener('keyup', function() {
					addTilesetDialogTileSizeKeyUp(this);
				});
			});
			// Adds a tileset to the tilesets list.
			let addTilesetDialogAdd = document.querySelector('button#addTilesetDialogAdd');
			addTilesetDialogAdd.addEventListener('click', function() {
				let name = document.querySelector('div#addTilesetDialogName > input').value;
				let tile_width = parseInt(addTilesetDialogTileSize[0].value);
				let tile_height = parseInt(addTilesetDialogTileSize[1].value);
				if (addTilesetDialogTileSizeKeyUp(addTilesetDialogTileSize[0]) && addTilesetDialogTileSizeKeyUp(addTilesetDialogTileSize[1])) {
					addTileset(name, {width: tile_width, height: tile_height});
					document.querySelector('div#addTilesetDialog').classList.add('hidden');
					return true;
				}
				return false;
			});

			window.canvas = document.getElementById('level');
			let main = document.getElementsByTagName('main')[0];
			window.context = canvas.getContext('2d');
			window.canvas.width = window.innerWidth;
			window.canvas.height = window.innerHeight;

			// resize the canvas when the window is resized
			window.onresize = function() {
				window.canvas.width = window.innerWidth;
				window.canvas.height = window.innerHeight;
			};

			// mouse events for panning the camera
			window.canvas.addEventListener('mousedown', function(evt) {
				window.mouse.is_down = true;
				window.mouse.x.start = evt.pageX;
				window.mouse.y.start = evt.pageY;
			});
			window.canvas.addEventListener('mouseup', function(evt) {
				window.mouse.is_down = false;
				window.mouse.x.end = evt.pageX;
				window.mouse.y.end = evt.pageY;
			});
			let camera_coordinates = document.getElementById('camera_coordinates');
			window.canvas.addEventListener('mousemove', function(evt) {
				// middle click (scroll wheel) and drag to pan the camera
				if (evt.which === 2 && window.mouse.is_down) {
					window.camera.x -= evt.pageX - window.mouse.x.start;
					window.camera.y -= evt.pageY - window.mouse.y.start;
					window.mouse.x.start = evt.pageX;
					window.mouse.y.start = evt.pageY;

					let editor_x = Math.round((window.camera.x - grid_cell_size / 2) / grid_cell_size);
					let editor_y = Math.round((window.camera.y - grid_cell_size / 2) / grid_cell_size);
					camera_coordinates.innerHTML = `${editor_x}, ${editor_y}`;
				}
			});
			// scroll to zoom in and out
			window.canvas.addEventListener('wheel', function(evt) {
				window.camera.zoom -= evt.deltaY / 1000;
				if (window.camera.zoom < 0.5) {
					window.camera.zoom = 0.5;
				}
				if (window.camera.zoom > 2.2) {
					window.camera.zoom = 2.2;
				}
			});

			canvas_init();
		}
	}

	// canvas_init initializes the level editor canvas.
	function canvas_init() {
		const canvas = document.getElementById('level');
		const ctx = canvas.getContext('2d');
		window.requestAnimationFrame(draw);
	}

	// draw handles drawing the level to the level editor canvas.
	function draw() {
		window.context.imageSmoothingEnabled = false;
		window.context.clearRect(0, 0, canvas.width, canvas.height);

		// draw the backgrounds
		for (let i = 0; i < window.backgrounds.images.length; i++) {
			let img = window.backgrounds.images[i];
			let x = (window.backgrounds.x - window.camera.x) % canvas.clientWidth;
			let y = window.backgrounds.y - window.camera.y;
			window.context.drawImage(window.backgrounds.images[i], x, y, canvas.width, canvas.height);
			window.context.drawImage(window.backgrounds.images[i], x - canvas.width, y, canvas.width, canvas.height);
			window.context.drawImage(window.backgrounds.images[i], x + canvas.width, y, canvas.width, canvas.height);
		}
		
		// draw a grid
		let grid = new Path2D();
		let zoomed_grid_cell_size = grid_cell_size * window.camera.zoom;
		for (let y = 0; y < window.canvas.height; y += zoomed_grid_cell_size) {
			for (let x = 0; x < window.canvas.width; x += zoomed_grid_cell_size) {
				let grid_x = x - (window.camera.x % zoomed_grid_cell_size);
				let grid_y = y - (window.camera.y % zoomed_grid_cell_size);
				grid.rect(grid_x, grid_y, zoomed_grid_cell_size, zoomed_grid_cell_size);
				grid.rect(grid_x - window.canvas.width, grid_y, zoomed_grid_cell_size, zoomed_grid_cell_size);
				grid.rect(grid_x + window.canvas.width, grid_y, zoomed_grid_cell_size, zoomed_grid_cell_size);
				grid.rect(grid_x, grid_y - window.canvas.height, zoomed_grid_cell_size, zoomed_grid_cell_size);
				grid.rect(grid_x - window.canvas.width, grid_y - window.canvas.height, zoomed_grid_cell_size, zoomed_grid_cell_size);
				grid.rect(grid_x + window.canvas.width, grid_y - window.canvas.height, zoomed_grid_cell_size, zoomed_grid_cell_size);
				grid.rect(grid_x, grid_y + window.canvas.height, zoomed_grid_cell_size, zoomed_grid_cell_size);
				grid.rect(grid_x - window.canvas.width, grid_y + window.canvas.height, zoomed_grid_cell_size, zoomed_grid_cell_size);
				grid.rect(grid_x + window.canvas.width, grid_y + window.canvas.height, zoomed_grid_cell_size, zoomed_grid_cell_size);

			}
		}
		window.context.fillStyle = '#eee';
		window.context.strokeStyle = '#eee';
		window.context.lineWidth = 0.5;
		window.context.stroke(grid);

		window.requestAnimationFrame(draw);
	}
	
	// addTilesetDialogTileSizeKeyUp checks if the tile size input is valid. A tile size
	// is valid if it is an integer.
	// @param elem: HTMLInputElement
	// @return bool
	function addTilesetDialogTileSizeKeyUp(elem) {
		if (elem.value.length == 0) {
			elem.classList.remove('good');
			elem.classList.add('bad');
			return false;
		}

		if (elem.value < 1) {
			elem.classList.remove('good');
			elem.classList.add('bad');
			return false;
		}

		elem.classList.remove('bad');
		elem.classList.add('good');
		return true;
	}

	// addTileset opens a file dialog and adds the selected file to the tilesets list.
	// A tileset is an image that is used to create a level. The tileset is split into
	// tiles that are used to create the level. The tileset is also used to create the
	// collision map for the level if the tiles are placed on the active layer.
	// @param tile_size: Object {width: int, height: int}
	// @return bool
	async function addTileset(name, tile_size) {
		let selected_file = await open({
			multiple: false,
			filters: [images_file_filter]
		});
		if (selected_file === null) {
			return false;
		}
		if (!(tile_size?.width !== undefined || tile_size?.height !== undefined)) {
			return false;
		}
		let file_path = Array.isArray(selected_file) ? selected_file[0] : selected_file
		let tileset = {
			name: (name === undefined || name.length == 0) ? file_path.split('\\').pop().split('/').pop() : name,
			path: file_path,
			img: new Image(),
			size: tile_size,
			id: uuid_v4()
		};
		tileset.img.src = convertFileSrc(file_path);
		tileset.img.crossOrigin = 'Anonymous';
		tilesets.push(tileset);
		

		tileset.img.addEventListener('load', function(evt) {
			console.log(tileset.img.width, tileset.img.height);
			// diceImage splits the tileset image into tiles.
			// @return Array of strings (base64 encoded images)
			function diceImage() {
				let canvas = document.createElement('canvas');
				canvas.width = tile_size.width;
				canvas.height = tile_size.height;
				let context = canvas.getContext('2d');
				let diced_img = new Array();

				// iterate through the tileset image based on the tile_size
				// and add each tile to the diced_img array as a dataURL
				for (let y = 0; y < tileset.img.height; y += tile_size.height) {
					for (let x = 0; x < tileset.img.width; x += tile_size.width) {
						context.clearRect(0, 0, canvas.width, canvas.height);
						context.drawImage(tileset.img, x, y, tile_size.width, tile_size.height, 0, 0, tile_size.width, tile_size.height);
						diced_img.push(canvas.toDataURL());
					}
				}

				return diced_img;
			}

			let diced_img = diceImage();
			let tileset_container = document.querySelector('div#tilesets');
			let tileset_div = document.createElement('div');
			tileset_div.classList.add('tileset');
			diced_img.forEach(function(data_url) {
				let img = document.createElement('img');
				img.classList.add('tile');
				img.src = data_url;
				tileset_div.appendChild(img);
			});
			let tileset_name = document.createElement('div');
			tileset_name.classList.add('tileset-name');
			tileset_name.innerHTML = tileset.name;
			tileset_container.appendChild(tileset_name);
			tileset_container.appendChild(tileset_div);
		});

		return true;
	}

	// addLayerDialogZIndexKeyUp checks if the z-index input is valid. A z-index is valid if it is an integer.
	// @param elem: HTMLInputElement
	// @return bool
	function addLayerDialogZIndexKeyUp(elem) {
		if (elem.value.length == 0) {
			elem.classList.remove('good');
			elem.classList.add('bad');
			return false;
		}

		for (let i = 0; i < window.layers.length; i++) {
			if (window.layers[i].z_index === parseInt(elem.value)) {
				elem.classList.remove('good');
				elem.classList.add('bad');
				return false;
			}
		}

		elem.classList.remove('bad');
		elem.classList.add('good');
		return true;
	}

	// addLayerDialogNameKeyUp checks if the layer name is valid and not already in use.
	// @param elem: HTMLInputElement
	// @return bool
	function addLayerDialogNameKeyUp(elem) {
		if (elem.value.length == 0) {
			elem.classList.remove('good');
			elem.classList.add('bad');
			return false;
		}

		for (let i = 0; i < window.layers.length; i++) {
			if (window.layers[i].name === elem.value) {
				elem.classList.remove('good');
				elem.classList.add('bad');
				return false;
			}
		}

		elem.classList.remove('bad');
		elem.classList.add('good');
		return true;
	}
	
	// addLayer adds a layer to the layers array and adds a list item to the layers list.
	// A layer is the layer of objects that are drawn in the game. Layer 0 is the active
	// layer that interacts with the player. Layers with a positive z-index are drawn
	// on top of the active layer, and layers with a negative z-index are drawn before
	// the active layer.
	// @param name: string
	// @param z_index: int
	function addLayer(name, z_index) {
		window.layers.push({
			name: name,
			z_index: z_index,
			objects: []
		});
		let layers = document.querySelector('ul#layers');
		let li = document.createElement('li');
		let span = document.createElement('span');
		span.innerHTML = name + '#' + z_index;
		li.appendChild(span);
		li.setAttribute('title', name + '#' + z_index );
		
		li.addEventListener('click', function() {
			let listItems = document.querySelectorAll('div#sidebar-container ul > li');
			for (let i = 0; i < listItems.length; i++) {
				listItems[i].classList.remove('selected');
			}
			this.classList.toggle('selected');
		});
		layers.appendChild(li);
	}

	// addBackground opens a file dialog and adds the selected file(s) to the backgrounds list.
	// The backgrounds list is a list of images that are drawn behind the layers in the game.
	// Backgrounds are drawn in the order they are added to the list. And the backgrounds
	// utilize parallax scrolling in the game (not in the editor).
	async function addBackground() {
		let selected_files = await open({
			multiple: true,
			filters: [images_file_filter]
		});

		// addFileToList adds a background to the backgrounds list and adds a list item
		// to the backgrounds list. The background is not added if it already exists in
		// the list.
		function addFileToList(path) {
			if (window.backgrounds.paths.includes(path)) {
				return;
			}
			window.backgrounds.paths.push(path);
			let img = new Image();
			img.src = convertFileSrc(path);
			window.backgrounds.images.push(img);

			let backgrounds = document.querySelector('ul#backgrounds');
			let li = document.createElement('li');
			let span = document.createElement('span');
			span.innerHTML = path.split('\\').pop().split('/').pop();
			li.appendChild(span);
			li.setAttribute('title', path);
			backgrounds.appendChild(li);
		}
		
		if (Array.isArray(selected_files)) {
			let backgrounds = document.querySelector('ul#backgrounds');
			for (let i = 0; i < selected_files.length; i++) {
				addFileToList(selected_files[i]);
			}
		} else if (selected_files !== null) {
			addFileToList(selected_files);
		}
	}
</script>

<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Manjari:wght@400;700&display=swap" rel="stylesheet">

<main>
	<!-- Add Layer Dialog -->
	<div id="addLayerDialog" class="dialog hidden">
		<div id="addLayerDialogHeader">
			Add Layer
		</div>
		<div id="addLayerDialogBody">
			<div id="addLayerDialogName">
				<input type="text" placeholder="Name">
			</div>
			<div id="addLayerDialogZIndex">
				<input type="number" placeholder="Z-Index" value="0">
			</div>
		</div>
		<div id="addLayerDialogFooter">
			<button id="addLayerDialogCancel" class="bad">Cancel</button>
			<button id="addLayerDialogAdd" class="good">Add</button>
		</div>
	</div>
	<!-- End Add Layer Dialog -->

	<!-- Add Tileset Dialog -->
	<div id="addTilesetDialog" class="dialog hidden">
		<div id="addTilesetDialogHeader">
			Add Tileset
		</div>
		<div id="addTilesetDialogBody">
			<div id="addTilesetDialogName">
				<input type="text" placeholder="Name">
			</div>
			<div id="addTilesetDialogTileSize">
				<input type="number" placeholder="Tile Width">
				<input type="number" placeholder="Tile Height">
			</div>
		</div>
		<div id="addTilesetDialogFooter">
			<button id="addTilesetDialogCancel" class="bad">Cancel</button>
			<button id="addTilesetDialogAdd" class="good">Add</button>
		</div>
	</div>
	<!-- End Add Tileset Dialog -->

	<!-- Canvas -->
	<div id="canvas-container">
		<canvas id="level"></canvas>
	</div>
	<!-- End Canvas -->

	<!-- Sidebar Toggler -->
	<div id="sidebar-opener">
		<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
			<path stroke-linecap="round" stroke-linejoin="round" d="M18.75 19.5l-7.5-7.5 7.5-7.5m-6 15L5.25 12l7.5-7.5" />
		</svg>
	</div>
	<!-- End Sidebar Toggler -->

	<!-- Sidebar -->
	<div id="sidebar-container">
		<div id="sidebar-header">
			<span id="camera_coordinates">x, y</span>
			Assets
		</div>

		<!-- Backgrounds -->
		<div id="background-container">
			<div id="addBackgroundBttn">
				<svg class="sidebar-svg" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
					<path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
				</svg>				  
			</div>
			<div class="sidebar-section-title">Backgrounds</div>
			<ul id="backgrounds"></ul>
		</div>
		<!-- End Backgrounds -->

		<!-- Layers -->
		<div id="asset-container">
			<div id="addLayerBttn">
				<svg class="sidebar-svg" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
					<path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
				</svg>				  
			</div>
			<div class="sidebar-section-title">Layers</div>
			<ul id="layers"></ul>
		</div>
		<!-- End Layers -->

		<!-- Tileset -->
		<div id="tileset-container">
			<div id="addTilesetBttn">
				<svg class="sidebar-svg" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
					<path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
				</svg>				  
			</div>
			<div class="sidebar-section-title">Tileset</div>
			<div id="tilesets"></div>
		</div>
		<!-- End Tileset -->
	</div>
	<!-- End Sidebar -->
</main>

<style lang="scss">
	@keyframes delayed_border_fadein {
		0% {
			border-color: #0000;
		}
		80% {
			border-color: #0000;
		}
		100% {
			border-color: #eeeb;
		}
	}

	// This ":global" thing makes me hate Svelte.

	:global(*) {
		margin: 0;
		padding: 0;
		box-sizing: border-box;
		font-family: Manjari;
	}

	:global(body) {
		background-color: #111;
		overflow: hidden;
	}

	:global(div#sidebar-container.sidebar-closed) {
		right: -400px !important;
	}

	:global(div#sidebar-opener.sidebar-closed) {
		animation: delayed_border_fadein 0.5s forwards;
		top: 0 !important;
		right: 0px !important;
		border-top-left-radius: 5px !important;
		border-bottom-left-radius: 5px !important;
		background-color: #22222a !important;
		> svg {
			transform: rotate(0deg);
		}
	}
	
	:global(.sidebar-section-title) {
		font-size: 1.1rem;
		margin-top: 3px;
		margin-bottom: 10px;
	}

	:global(.sidebar-svg) {
		width: 25px;
		height: 25px;
		margin: -5px;
		float: right;
		cursor: pointer;
	}

	button.bad:hover {
		background-color: #5a3a46 !important;
	}

	button.good:hover {
		background-color: #3a5a46 !important;
	}

	:global(input.bad), :global(input.bad) {
		border-color: #7a3a46 !important;
		transition: border-color 0.2s;
		box-shadow: 0px 0px 5px 0px #5a3a46 inset;
	}
	
	:global(input.good), :global(input.good) {
		border-color: #3a7a46 !important;
		transition: border-color 0.2s;
		box-shadow: 0px 0px 5px 0px #3a5a46 inset;
	}

	:global(.hidden) {
		display: none !important;
	}

	:global(div#sidebar-container ul li.selected span) {
		background-color: #467afa88 !important;
	}

	:global(div#sidebar-container ul li.selected span::before) {
		background-color: #467afa88;
		content: "●";
	}

	:global(div#sidebar-container ul) {
		list-style-type: none;
		margin-left: 20px;

		:global(li) {
			margin: 7px 0px;
			position: relative;

			// custom bullet point
			:global(span::before) {
				content: "○";
				display: block;
				width: 10px;
				height: 10px;
				position: absolute;
				top: 0px;
				left: -20px;
				padding: 4px 4px 12px 6px;
				border-top-left-radius: 5px;
				border-bottom-left-radius: 5px;
				transition: background-color 0.1s;
			}

			:global(span) {
				cursor: pointer;
				position: relative;
				left: -3px;
				padding: 6px 8px 2px 5px;
				border-top-right-radius: 5px;
				border-bottom-right-radius: 5px;
				transition: background-color 0.1s;
			}
		}
	}

	main {
		width: 100%;
		height: 100%;

		::-webkit-scrollbar {
			width: 5px;
		}

		::-webkit-scrollbar-thumb {
			background-color: #eee9;
			border-radius: 50px;

			&:hover {
				background-color: #eee;
			}
		}

		> div.dialog {
			position: fixed;
			width: 350px;
			background-color: #22222a;
			color: white;
			border-radius: 5px;
			font-size: 13.5pt;
			padding: 15px 25px;
			top: calc(50% - 100px);
			left: calc(50% - 175px);
			box-shadow: 0px 0px 10px 1px #fffa, 0px 0px 5px 0px #fffa inset;
			border: 1px solid white;
			z-index: 1000;

			> * {
				margin: 5px 0px;
			}

			input {
				margin: 4px 0px;
				padding: 10px 8px 3px 8px;
				font-size: 13.5pt;
				color: white;
				background-color: #2d2d36;
				outline: none;
				border: 1px solid #aaa;
				border-radius: 4px;
				width: 100%;
			}

			button {
				margin: 10px 5px 3px 5px;
				padding: 8px 12px 2px 12px;
				font-size: 13.5pt;
				background-color: #2d2d36;
				outline: none;
				border: 1px solid #eeeb;
				border-radius: 3px;
				color: white;
				cursor: pointer;
				transition: background-color 0.1s;
				float: right;
			}
		}

		> div#canvas-container {
			width: 100vw;
			height: 100vh;
			display: flex;
			justify-content: center;
			align-items: center;
			position: fixed;
			top: 0;
			left: 0;
		}

		> div#sidebar-opener {
			transition: all 0.5s ease-in-out;
			background-color: #0000;
			color: #eee;
			cursor: pointer;
			position: absolute;
			width: 36px;
			top: 3px;
			right: 364px;
			padding: 5px 3px 0px 3px;
			z-index: 5;
			border: 1px solid #0000;
			border-right: none;
			border-top-left-radius: 0;
			border-bottom-left-radius: 0;

			> svg {
				transform: rotate(180deg);
				transition: all 0.2s ease-in;
			}
		}

		> div#sidebar-container {
			width: 400px;
			height: 100%;
			position: absolute;
			top: 0;
			right: 0;
			color: #eee;
			background-color: #22222a;
			display: flex;
			flex-flow: column nowrap;
			transition: all 0.5s ease-in-out;

			> * {
				border: 1px solid #eeeb;
				padding: 15px 15px 10px 15px;
			}

			> *:not(:first-child) {
				border-top: none;
			}

			> div#sidebar-header {
				font-size: 1.2rem;
				text-align: center;
				position: relative;

				> span#camera_coordinates {
					position: absolute;
					right: 10px;
					margin-top: 3px;
					font-size: 0.825rem;
					color: #aaa;
				}
			}

			div#tileset-container {
				overflow-y: auto;

				

				div#tilesets {
					display: flex;
					flex-direction: column;

					:global(div.tileset-name) {
						margin-bottom: 5px;
						border-bottom: 1px solid #eeeb;
					}

					> :global(.tileset) {
						display: grid;
						grid-template-columns: repeat(auto-fill, 40px);
						gap: 5px;
						justify-content: space-between;

						&:not(:last-of-type) {
							margin-bottom: 25px;
						}

						> :global(.tile) {
							cursor: pointer;
							border: 1px solid #ccca;
							border-color: #ccca;
							box-shadow: 0 0 5px 0 #0000;
							width: 40px !important;
							height: 40px !important;
							transition: border-color 0.1s, box-shadow 0.1s;

							&:hover {
								border-color: #ffff;
								box-shadow: 0px 0px 5px 0px #ffff;
							}
						}

						> :global(.tile.selected) {
							border-color: #ffff;
							box-shadow: 0px 0px 5px 0px #ffff;
						}
					}
				}
			}
		}
	}
</style>
