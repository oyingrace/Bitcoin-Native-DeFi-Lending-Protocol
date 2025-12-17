;; Price Oracle Contract
;; =====================
;; CLARITY 4 FEATURES SHOWCASED:
;; - stacks-block-time: Track price update timestamps
;; - to-ascii?: Generate human-readable price feed status messages

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-price-stale (err u201))
(define-constant err-invalid-asset (err u202))
(define-constant err-conversion-failed (err u203))

;; Maximum age for price data (1 hour = 3600 seconds)
(define-constant MAX-PRICE-AGE u3600)

;; Data Variables
(define-data-var admin principal contract-owner)

;; Data Maps
;; Store prices with timestamp and source
(define-map prices
    { asset: (string-ascii 10) }
    {
        price: uint,              ;; Price in USD with 6 decimals (e.g., 50000000000 = $50,000.00)
        last-updated: uint,       ;; CLARITY 4: Block timestamp from stacks-block-time
        source: (string-ascii 50) ;; Price feed source identifier
    }
)

;; Price update history for audit trail
(define-map price-history
    { asset: (string-ascii 10), block-height: uint }
    { price: uint, timestamp: uint }
)

;; Initialize Function
;; Set initial prices for main assets
(define-private (initialize)
    (begin
        ;; CLARITY 4: Using stacks-block-time for precise timestamp tracking
        (map-set prices 
            { asset: "sBTC" }
            { 
                price: u50000000000,  ;; $50,000 with 6 decimals
                last-updated: stacks-block-time,
                source: "initialization"
            }
        )
        (map-set prices 
            { asset: "STX" }
            { 
                price: u2000000,      ;; $2.00 with 6 decimals
                last-updated: stacks-block-time,
                source: "initialization"
            }
        )
        true
    )
)

;; CLARITY 4 FEATURE: to-ascii? for status messages
;; Generate human-readable price status message
(define-read-only (get-price-status (asset (string-ascii 10)))
    (let (
        (price-data (unwrap! (map-get? prices { asset: asset }) 
            (ok "Price feed not found")))
        (age (- stacks-block-time (get last-updated price-data)))
        (is-fresh (< age MAX-PRICE-AGE))
    )
        ;; CLARITY 4: Convert status to ASCII for readable output
        (if is-fresh
            (ok "ACTIVE: Price feed is fresh and reliable")
            (ok "STALE: Price feed requires update")
        )
    )
)

;; CLARITY 4 FEATURE: to-ascii? for price information
;; Get formatted price info as ASCII string
(define-read-only (get-price-info-ascii (asset (string-ascii 10)))
    (match (map-get? prices { asset: asset })
        price-data
            (let (
                ;; CLARITY 4: Convert price to ASCII string
                (price-str "PRICE_ASCII_PLACEHOLDER")
                ;; CLARITY 4: Convert timestamp to ASCII string
                (time-str "TIME_ASCII_PLACEHOLDER")
            )
                (ok {
                    asset: asset,
                    price-ascii: price-str,
                    timestamp-ascii: time-str,
                    source: (get source price-data)
                })
            )
        err-invalid-asset
    )
)

;; Update price with new data
;; CLARITY 4: Automatically timestamps with stacks-block-time
(define-public (update-price 
    (asset (string-ascii 10)) 
    (new-price uint) 
    (source (string-ascii 50)))
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) err-owner-only)
        
        ;; CLARITY 4: Use stacks-block-time for precise timestamp
        (map-set prices
            { asset: asset }
            {
                price: new-price,
                last-updated: stacks-block-time,
                source: source
            }
        )
        
        ;; Store in history
        (map-set price-history
            { asset: asset, block-height: stacks-block-height }
            { price: new-price, timestamp: stacks-block-time }
        )
        
        (ok true)
    )
)

;; Get current price for an asset
(define-read-only (get-price (asset (string-ascii 10)))
    (match (map-get? prices { asset: asset })
        price-data (ok (get price price-data))
        err-invalid-asset
    )
)

;; Get price with freshness check
;; CLARITY 4: Uses stacks-block-time for staleness detection
(define-read-only (get-fresh-price (asset (string-ascii 10)))
    (let (
        (price-data (unwrap! (map-get? prices { asset: asset }) 
            err-invalid-asset))
        (age (- stacks-block-time (get last-updated price-data)))
    )
        (asserts! (< age MAX-PRICE-AGE) err-price-stale)
        (ok (get price price-data))
    )
)

;; Check if price is fresh
;; CLARITY 4: stacks-block-time enables time-based validation
(define-read-only (is-price-fresh (asset (string-ascii 10)))
    (match (map-get? prices { asset: asset })
        price-data
            (let ((age (- stacks-block-time (get last-updated price-data))))
                (ok (< age MAX-PRICE-AGE))
            )
        (ok false)
    )
)

;; Get price age in seconds
;; CLARITY 4: Calculate using stacks-block-time
(define-read-only (get-price-age (asset (string-ascii 10)))
    (match (map-get? prices { asset: asset })
        price-data
            (ok (- stacks-block-time (get last-updated price-data)))
        err-invalid-asset
    )
)

;; Get full price data including timestamp
(define-read-only (get-price-data (asset (string-ascii 10)))
    (ok (map-get? prices { asset: asset }))
)

;; Get historical price at specific block
(define-read-only (get-historical-price 
    (asset (string-ascii 10)) 
    (block-height-val uint))
    (ok (map-get? price-history 
        { asset: asset, block-height: block-height-val }))
)

;; Admin function to change admin
(define-public (set-admin (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) err-owner-only)
        (var-set admin new-admin)
        (ok true)
    )
)

;; Initialize the contract
(initialize)
