;; Liquidator Trait
;; Standard interface for liquidator contracts
;; Enables verified third-party liquidation bots

(define-trait liquidator-trait
    (
        ;; Liquidate an undercollateralized position
        ;; Returns the amount of collateral seized
        (liquidate (principal uint) (response uint uint))
        
        ;; Get the liquidation bonus percentage (in basis points)
        (get-liquidation-bonus () (response uint uint))
        
        ;; Check if a position is eligible for liquidation
        (can-liquidate (principal) (response bool uint))
    )
)
