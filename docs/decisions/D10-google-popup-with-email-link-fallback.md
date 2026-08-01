# D10. Google sign-in popup only, with an email-link fallback. No redirect.

Kind: implementation

Since Firebase JS SDK v9.15, `signInWithRedirect` cannot complete on Safari or
iOS when `authDomain` is a different origin than the app. GitHub Pages serves
from `*.github.io` while `authDomain` is `*.firebaseapp.com`, so it is always
cross-origin, and Pages is static so the same-origin auth-helper fix is not
available. Storage partitioning drops the pending redirect state and the player
returns silently signed out. GolfModel shipped redirect as a fallback and
documented that it does not work.

Popup is the only Google path. A blocked popup falls through to a passwordless
email link, which navigates to our own origin and has nothing to partition.

Consequence to remember: adding a `Cross-Origin-Opener-Policy: same-origin`
header would break `signInWithPopup` outright. Pages does not set one.
