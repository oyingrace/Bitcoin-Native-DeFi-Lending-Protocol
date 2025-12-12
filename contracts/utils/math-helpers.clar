;; Math Helpers - Utility functions for calculations
;; Provides safe mathematical operations for DeFi protocols

;; Constants
(define-constant PRECISION u1000000) ;; 6 decimal precision for percentages
(define-constant SECONDS-PER-YEAR u31536000) ;; 365 days in seconds
(define-constant err-overflow (err u100))
(define-constant err-division-by-zero (err u101))

;; Calculate percentage of a value
;; Returns (value * percentage) / 100
(define-read-only (calculate-percentage (value uint) (percentage uint))
    (ok (/ (* value percentage) u100))
)

;; Calculate interest for a given principal, rate, and time period
;; rate is expressed in basis points (1% = 100)
;; time-elapsed is in seconds
(define-read-only (calculate-interest 
    (principal uint) 
    (annual-rate-bps uint) 
    (time-elapsed uint))
    (let (
        (rate-per-second (/ annual-rate-bps SECONDS-PER-YEAR))
        (interest (/ (* (* principal rate-per-second) time-elapsed) u10000))
    )
        (ok interest)
    )
)

;; Calculate health factor: (collateral-value * 100) / debt-value
;; Returns percentage (150 = 150% = 1.5x collateralization)
(define-read-only (calculate-health-factor 
    (collateral-value uint) 
    (debt-value uint))
    (if (is-eq debt-value u0)
        (ok u0) ;; No debt = infinite health (return 0 as special case)
        (ok (/ (* collateral-value u100) debt-value))
    )
)

;; Safe multiplication with overflow check
(define-read-only (safe-mul (a uint) (b uint))
    (let ((result (* a b)))
        (if (and (> a u0) (< result a))
            err-overflow
            (ok result)
        )
    )
)

;; Safe division with zero check
(define-read-only (safe-div (a uint) (b uint))
    (if (is-eq b u0)
        err-division-by-zero
        (ok (/ a b))
    )
)

;; Calculate liquidation bonus (e.g., 10% = 110 returned)
(define-read-only (apply-liquidation-bonus 
    (amount uint) 
    (bonus-bps uint))
    (ok (+ amount (/ (* amount bonus-bps) u10000)))
)

;; Calculate compound interest (simplified daily compounding)
(define-read-only (calculate-compound-interest
    (principal uint)
    (annual-rate-bps uint)
    (days-elapsed uint))
    (let (
        (daily-rate (/ annual-rate-bps u36500)) ;; annual rate / 365 days
        (interest (/ (* (* principal daily-rate) days-elapsed) u100))
    )
        (ok interest)
    )
)
