// animations.ts

// Slide in from top
export function slideInFromTop(variant: "hidden" | "visible") {
    return {
      hidden: {
        y: '-100vh',
        opacity: 0
      },
      visible: {
        y: '0',
        opacity: 1,
        transition: {
          type: 'spring',
          stiffness: 60,
          damping: 20
        }
      }
    }
  }
  
  // Slide in from bottom
  export const slideInFromBottom = {
    hidden: { y: '100vh', opacity: 0 },
    visible: { y: '0', opacity: 1, transition: { type: 'spring', stiffness: 70, damping: 20 } }
  }
  
  // Slide in from left
  export const slideInFromLeft = {
    hidden: { x: '-100vw', opacity: 0 },
    visible: { x: '0', opacity: 1, transition: { type: 'spring', stiffness: 70, damping: 20 } }
  }
  
  // Slide in from right
  export const slideInFromRight = {
    hidden: { x: '100vw', opacity: 0 },
    visible: { x: '0', opacity: 1, transition: { type: 'spring', stiffness: 70, damping: 20 } }
  }
  
  // Fade in
  export const fadeIn = {
    hidden: { opacity: 0 },
    visible: { opacity: 1, transition: { duration: 1 } }
  }