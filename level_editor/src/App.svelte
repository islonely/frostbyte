<script>
	import { open } from '@tauri-apps/api/dialog';
	import { convertFileSrc } from '@tauri-apps/api/tauri';

	window.backgrounds = {
		paths: [],
		images: [],
		x: 0,
		y: 0,
	};

	window.camera = {
		x: -50,
		y: 0,
	}

	window.mouse = {
		start_x: 0,
		start_y: 0,
		is_down: false
	}

	window.layers = [];

	document.onreadystatechange = function () {
		if (document.readyState === 'complete') {
			
			let sidebar = document.querySelector('div#sidebar-container');
			let openSidebarBttn = document.querySelector('div#sidebar-opener');
			openSidebarBttn.addEventListener('click', function() {
				sidebar.classList.toggle('sidebar-closed')
				openSidebarBttn.classList.toggle('sidebar-closed')
			})

			let addBackgroundBttn = document.querySelector('div#addBackgroundBttn');
			addBackgroundBttn.addEventListener('click', async function() {
				await addBackground();
			});

			let addLayerBttn = document.querySelector('div#addLayerBttn');
			addLayerBttn.addEventListener('click', function() {
				document.querySelector('div#addLayerDialog').classList.remove('hidden');
			});
			let addLayerDialogZIndex = document.querySelector('div#addLayerDialogZIndex > input');
			addLayerDialogZIndex.addEventListener('keyup', function() {
				addLayerDialogZIndexKeyUp(this);
			});
			let addLayerDialogName = document.querySelector('div#addLayerDialogName > input');
			addLayerDialogName.addEventListener('keyup', function() {
				addLayerDialogNameKeyUp(this);
			});
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
			let addLayerDialogCancel = document.querySelector('button#addLayerDialogCancel');
			addLayerDialogCancel.addEventListener('click', function() {
				document.querySelector('div#addLayerDialog').classList.add('hidden');
			});

			window.canvas = document.getElementById('level');
			let main = document.getElementsByTagName('main')[0];
			window.context = canvas.getContext('2d');
			window.canvas.width = window.innerWidth;
			window.canvas.height = window.innerHeight;

			window.onresize = function() {
				window.canvas.width = window.innerWidth;
				window.canvas.height = window.innerHeight;
			}



			canvas_init();
		}
	}

	function canvas_init() {
		const canvas = document.getElementById('level');
		const ctx = canvas.getContext('2d');
		window.requestAnimationFrame(draw);
	}

	function draw() {
		window.context.imageSmoothingEnabled = false;
		window.context.clearRect(0, 0, canvas.width, canvas.height);

		

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
		let cell_size = 40;
		for (let y = 0; y < window.canvas.height; y += cell_size) {
			for (let x = 0; x < window.canvas.width; x += cell_size) {
				let grid_x = (x - window.camera.x) % window.canvas.width;
				let grid_y = (y - window.camera.y) % window.canvas.height;
				grid.rect(grid_x, grid_y, cell_size, cell_size);
				grid.rect(grid_x - window.canvas.width, grid_y, cell_size, cell_size);
				grid.rect(grid_x + window.canvas.width, grid_y, cell_size, cell_size);
				grid.rect(grid_x, grid_y - window.canvas.height, cell_size, cell_size);
				grid.rect(grid_x - window.canvas.width, grid_y - window.canvas.height, cell_size, cell_size);
				grid.rect(grid_x + window.canvas.width, grid_y - window.canvas.height, cell_size, cell_size);
				grid.rect(grid_x, grid_y + window.canvas.height, cell_size, cell_size);
				grid.rect(grid_x - window.canvas.width, grid_y + window.canvas.height, cell_size, cell_size);
				grid.rect(grid_x + window.canvas.width, grid_y + window.canvas.height, cell_size, cell_size);

			}
		}
		window.context.fillStyle = '#eee';
		window.context.strokeStyle = '#eee';
		window.context.lineWidth = 0.5;
		window.context.stroke(grid);

		window.requestAnimationFrame(draw);
	}

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
			console.log(li);
			li.classList.add('selected');
		});
		layers.appendChild(li);
	}

	async function addBackground() {
		let selected_files = await open({
			multiple: true,
			filters: [{
				name: 'Images',
				extensions: ['png', 'jpg', 'jpeg', 'bmp']
			}]
		});

		function addFileToList(path) {
			if (window.backgrounds.paths.includes(path)) {
				return null;
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
			console.log(window.backgrounds)
		}
		
		if (Array.isArray(selected_files)) {
			let backgrounds = document.querySelector('ul#backgrounds');
			for (let i = 0; i < selected_files.length; i++) {
				addFileToList(selected_files[i]);
			}
		} else if (selected_files !== null) {
			addFileToList(selected_files);
		}

		return null;
	}
</script>

<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Manjari:wght@400;700&display=swap" rel="stylesheet">

<main>
	<div id="addLayerDialog" class="hidden">
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

	<div id="canvas-container">
		<canvas id="level"></canvas>
	</div>
	<div id="sidebar-opener">
		<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
			<path stroke-linecap="round" stroke-linejoin="round" d="M18.75 19.5l-7.5-7.5 7.5-7.5m-6 15L5.25 12l7.5-7.5" />
		</svg>
	</div>
	<div id="sidebar-container">
		<div id="sidebar-header">
			Assets
		</div>
		<div id="background-container">
			<div id="addBackgroundBttn">
				<svg class="sidebar-svg" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
					<path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
				</svg>				  
			</div>
			<div class="sidebar-section-title">Backgrounds</div>
			<ul id="backgrounds"></ul>
		</div>
		<div id="asset-container">
			<div id="addLayerBttn">
				<svg class="sidebar-svg" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
					<path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
				</svg>				  
			</div>
			<div class="sidebar-section-title">Layers</div>
			<ul id="layers"></ul>
		</div>
	</div>
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
		right: -350px !important;
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

		> div#addLayerDialog {
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
			right: 314px;
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
			width: 350px;
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
			}
		}
	}
</style>
