//variables
const numBalls = 100;
const speed = .25;
const gravity = .1;
const friction = 1;
const ctx = document.querySelector('.canvas');

let ballSize = {
	min : null,
	max : null
}

let windowSize = {
	w : window.innerWidth,
	h : window.innerHeight
}

let mouse = {
	x : windowSize.w / 2,
	y : windowSize.h / 2
}

let colors = ['#EF3A38', '#2e99b0', '#3a0088'];
let emojiArray = ['💥', '✨', '🏃‍♀️', '⚡️', '🏃‍♂️', '⌨️', '🖥️'];


//events
window.addEventListener('mousemove', function(e) {
	mouse.x = e.clientX,
	mouse.y = e.clientY
});

window.addEventListener('resize', resizeDetect);


//utility functions
function resizeDetect () {
	windowSize.w = window.innerWidth;
	windowSize.h = window.innerHeight;
	ballSize.min = Math.round(windowSize.w/10 - 150);
	ballSize.max = Math.round(windowSize.w/10 + 100);
}

function randomIntFromRange(min, max) {
    return Math.floor(Math.random() * (max - min + 1) + min);
}

function randomColor(colors) {
    return colors[Math.floor(Math.random() * colors.length)];
}

function Ball(x, y, z, dx, dy, radius, fontSize) {
	let el = document.createElement('div');
	var emoji = document.createTextNode( emojiArray[randomIntFromRange(0, emojiArray.length - 1)] );
	el.appendChild(emoji);
	this.fontSize = fontSize,
	this.x = x,
	this.y = y,
	this.z = z,
	this.dx = dx,
	this.dy = dy,
	this.radius = radius,
	this.update = function() {
		if (this.y + this.radius + this.dy > windowSize.h) {
			this.dy = -this.dy * friction;
		} else {
			this.dy += gravity; 
		}
		if (this.x + this.radius> windowSize.w || this.x <= 0) {
			this.dx = -this.dx;
		}
		
		this.x += this.dx;
		this.y += this.dy;
		el.style.transform = `translate3d(${this.x}px, ${this.y}px, 0)`;
	},
	this.draw = function() {
		el.style.fontSize = this.fontSize + 'vw';
		el.className = 'ball';
		ctx.appendChild(el); 
		el.style.width = this.radius;
		el.style.height = this.radius;
		el.style.zIndex = z;
		el.style.transform = `translate3d(${x}px, ${y}px, 0)`;
	}
}
//ball Object
var ball;
var ballArray = [];

var createEls = function(click) {
	if (click) {
		makeBalls = 1;
	} else {
		// ballArray = [];
		makeBalls = numBalls;
	}
	for (let i = 0; i < makeBalls; i++) {
		var radius = randomIntFromRange(ballSize.min, ballSize.max);
		var z = randomIntFromRange(1, numBalls);
		var fontSize = randomIntFromRange(5, 11);
		if (click) {
			var x = mouse.x - radius;
			var y = mouse.y - radius;
		} else {
			var x = randomIntFromRange(0, windowSize.w - radius);
			var y = randomIntFromRange(0, windowSize.h - radius);
		}
		let dx = randomIntFromRange(-speed, speed);
		let dy = randomIntFromRange(-speed, speed);
		// var dx = speed;
		// var dy = speed;
		ballArray.push(new Ball(x, y, z, dx, dy, radius, fontSize));
		ballArray[i].draw();
	}
}

function animate() {
	// requestAnimationFrame(animate);
	for (let i = 0; i < ballArray.length; i++) {
		ballArray[i].update();
	} 
}

// window.addEventListener('click', function(){
// 	createEls(true);
// }, false);

setInterval(function(){
	requestAnimationFrame(animate);
}, 10);

resizeDetect();
createEls(false);

// console.log(ballArray);