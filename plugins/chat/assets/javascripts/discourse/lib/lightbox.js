import "photoswipe/style.css";
import PhotoSwipeLightbox from "photoswipe/lightbox";

export default async function lightbox(images) {
  if (!images || !images.length) {
    return;
  }

  const pswpLightbox = new PhotoSwipeLightbox({
    gallery: images[0].parentElement,
    children: "img",
    pswpModule: () => import("photoswipe"),
  });

  pswpLightbox.init();
}
