import "photoswipe/style.css";
import PhotoSwipeLightbox from "photoswipe/lightbox";
import { SELECTORS } from "discourse/lib/lightbox/constants";

let currentLightbox;

/**
 * Initialize PhotoSwipe lightboxes in a container.
 *
 * @param {HTMLElement} container The element containing images
 * @param {string} [selector] CSS selector for lightbox links
 */
export async function setupLightboxes({ container, selector }) {
  cleanupLightboxes();

  if (!container) {
    return;
  }

  currentLightbox = new PhotoSwipeLightbox({
    gallery: container,
    children: selector || SELECTORS.DEFAULT_ITEM_SELECTOR,
    pswpModule: () => import("photoswipe"),
  });

  currentLightbox.init();
}

/**
 * Destroy the active lightbox instance.
 */
export function cleanupLightboxes() {
  currentLightbox?.destroy();
  currentLightbox = null;
}

/**
 * Convenience helper to set up lightboxes on an element.
 *
 * @param {HTMLElement} elem
 */
export default function lightbox(elem) {
  setupLightboxes({ container: elem });
}
