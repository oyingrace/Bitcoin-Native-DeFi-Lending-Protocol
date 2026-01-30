;; title: governance-treasury
;; version: 1.0.0
;; summary: DAO-controlled treasury
;; description: Treasury managed by governance votes - Clarity 4

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u4500))
(define-constant ERR-INSUFFICIENT-FUNDS (err u4501))

;; Data Variables
(define-data-var treasury-balance uint u0)
(define-data-var total-spent uint u0)

;; Data Maps - Using stacks-block-time for Clarity 4
(define-map spending-records uint {
  recipient: principal,
  amount: uint,
  purpose: (string-ascii 100),
  spent-at: uint  ;; Clarity 4: Unix timestamp
})

(define-data-var next-spending-id uint u1)

;; Public Functions

(define-public (deposit-to-treasury (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender tx-sender))
    (var-set treasury-balance (+ (var-get treasury-balance) amount))

    (print {
      event: "treasury-deposit",
      depositor: tx-sender,
      amount: amount,
      timestamp: stacks-block-time
    })

    (ok true)
  )
)

(define-public (execute-spending (recipient principal) (amount uint) (purpose (string-ascii 100)))
  (let (
    (spending-id (var-get next-spending-id))
  )
  (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (<= amount (var-get treasury-balance)) ERR-INSUFFICIENT-FUNDS)

    (try! (begin (stx-transfer? amount tx-sender recipient)))

    (map-set spending-records spending-id {
      recipient: recipient,
      amount: amount,
      purpose: purpose,
      spent-at: stacks-block-time
    })