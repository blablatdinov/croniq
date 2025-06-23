export default {
  mounted() {
    if (window.grecaptcha) {
      this.renderCaptcha();
    } else {
      window.renderCaptchaCallback = () => this.renderCaptcha();
    }
  },
  renderCaptcha() {
    if (!this.el.querySelector(".g-recaptcha")?.hasChildNodes()) {
      console.log(this.el.dataset.sitekey);
      grecaptcha.render(this.el.querySelector(".g-recaptcha"), {
        sitekey: this.el.dataset.sitekey,
        callback: (token) => {
          const hiddenInput = document.getElementById("recaptcha_token");
          if (hiddenInput) {
            hiddenInput.value = token;
          }
        }
      });
    }
  }
};
