<script>
	import { open } from '@tauri-apps/api/dialog';

	window.backgrounds = {
		paths: [],
		images: []
	};

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

			let canvas = document.getElementById('level');
			let main = document.getElementsByTagName('main')[0];
			let context = canvas.getContext('2d');
			canvas.width = window.innerWidth-10;
			canvas.height = window.innerHeight-10;

			window.onresize = function() {
				canvas.width = window.innerWidth-10;
				canvas.height = window.innerHeight-10;
			}

			canvas_init();
		}
	}

	function canvas_init() {
		window.requestAnimationFrame(draw);
	}

	function draw() {
		const ctx = document.getElementById('level').getContext('2d');
		ctx.globalCompositeOperation = 'destination-over';
		ctx.clearRect(0, 0, ctx.width, ctx.height);
		for (let i = 0; i < window.backgrounds.images.length; i++) {
			ctx.drawImage(window.backgrounds.images[i], 0, 0, ctx.width, ctx.height);
		}

		window.requestAnimationFrame(draw);
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
			img.src = path;
			console.log(path)
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

		return null;
	}
</script>

<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Manjari:wght@400;700&display=swap" rel="stylesheet">

<main>
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
			sfd
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

	main {
		width: 100%;
		height: 100%;

		> div#canvas-container {
			width: 100%;
			height: 100%;
			display: flex;
			justify-content: center;
			align-items: center;
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

			> div#background-container {

				ul {
					list-style-type:circle;
					margin-left: 20px;

					li span {
						position: relative;
						left: -5px;
					}
				}
			}
		}
	}
</style>
