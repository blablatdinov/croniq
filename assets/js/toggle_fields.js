const ToggleFields = {
  mounted() {
    this.updateVisibility();
  },

  updated() {
    this.updateVisibility();
  },

  updateVisibility() {
    const shouldShow = this.el.dataset.show === "true";
    console.log("ToggleFields: shouldShow =", shouldShow, "for element:", this.el.id);
    this.el.style.display = shouldShow ? "block" : "none";
  }
};

export default ToggleFields; 