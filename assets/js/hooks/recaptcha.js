let RecaptchaHook = {
  mounted() {
    console.log('mounted');
    grecaptcha.ready(() => {
      grecaptcha.execute(this.el.dataset.sitekey, { action: "register" })
        .then(token => {
          this.el.value = token;
        });
    });
  },
  updated() {
    console.log('updated');
    grecaptcha.ready(() => {
      grecaptcha.execute(this.el.dataset.sitekey, { action: "register" })
        .then(token => {
          this.el.value = token;
        });
    });
  }
};

export default RecaptchaHook;