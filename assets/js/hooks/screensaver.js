export const Screensaver = {
  mounted() {
    this.initializeScreensaver();
  },

  initializeScreensaver() {
    this.logo = document.getElementById('screensaver-logo');

    if (!this.logo) {
      this.initTimeout = setTimeout(() => this.initializeScreensaver(), 50);
      return;
    }

    this.container = this.el;

    this.logoWidth = 200;
    this.logoHeight = 43;

    this.x = Math.random() * (window.innerWidth - this.logoWidth);
    this.y = Math.random() * (window.innerHeight - this.logoHeight);

    this.vx = (Math.random() - 0.5) * 400;
    this.vy = (Math.random() - 0.5) * 400;

    this.rotation = Math.random() * 360;
    this.rotationVelocity = (Math.random() - 0.5) * 180;

    this.lastTime = performance.now();

    this.animate = this.animate.bind(this);
    this.animationFrame = requestAnimationFrame(this.animate);
  },

  animate(currentTime) {
    const deltaTime = (currentTime - this.lastTime) / 1000;
    this.lastTime = currentTime;

    this.x += this.vx * deltaTime;
    this.y += this.vy * deltaTime;
    this.rotation += this.rotationVelocity * deltaTime;

    const maxX = window.innerWidth - this.logoWidth;
    const maxY = window.innerHeight - this.logoHeight;

    if (this.x <= 0) {
      this.x = 0;
      this.vx = Math.abs(this.vx);
      this.rotationVelocity = (Math.random() - 0.5) * 180;
    } else if (this.x >= maxX) {
      this.x = maxX;
      this.vx = -Math.abs(this.vx);
      this.rotationVelocity = (Math.random() - 0.5) * 180;
    }

    if (this.y <= 0) {
      this.y = 0;
      this.vy = Math.abs(this.vy);
      this.rotationVelocity = (Math.random() - 0.5) * 180;
    } else if (this.y >= maxY) {
      this.y = maxY;
      this.vy = -Math.abs(this.vy);
      this.rotationVelocity = (Math.random() - 0.5) * 180;
    }

    this.logo.style.left = `${this.x}px`;
    this.logo.style.top = `${this.y}px`;
    this.logo.style.transform = `rotate(${this.rotation}deg)`;

    this.animationFrame = requestAnimationFrame(this.animate);
  },

  destroyed() {
    if (this.initTimeout) {
      clearTimeout(this.initTimeout);
    }
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
    }
  }
};
