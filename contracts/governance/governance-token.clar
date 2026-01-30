;; title: governance-token
;; version: 1.0.0
;; summary: ChainChat governance token
;; description: SIP-010 fungible token for governance - Clarity 4

;; Implement SIP-010 trait

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u4000))
(define-constant ERR-NOT-TOKEN-OWNER (err u4001))
(define-constant ERR-INSUFFICIENT-BALANCE (err u4002))

;; Token definitions
(define-fungible-token chainchat-token u1000000000000000)  ;; 1B tokens with 6 decimals

;; Data Variables
(define-data-var token-name (string-ascii 32) "ChainChat")
(define-data-var token-symbol (string-ascii 10) "CHAT")
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var token-decimals uint u6)

;; SIP-010 Functions

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq tx-sender sender) (is-eq contract-caller sender)) ERR-UNAUTHORIZED)
    (try! (ft-transfer? chainchat-token amount sender recipient))
    (match memo to-print (print to-print) 0x)
    (ok true)
  )
)

(define-read-only (get-name)
  (ok (var-get token-name))
)

(define-read-only (get-symbol)
  (ok (var-get token-symbol))
)

(define-read-only (get-decimals)
  (ok (var-get token-decimals))
)

(define-read-only (get-balance (who principal))
  (ok (ft-get-balance chainchat-token who))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply chainchat-token))
)

(define-read-only (get-token-uri)
  (ok (var-get token-uri))
)

;; Mint function (only contract owner)
(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (ft-mint? chainchat-token amount recipient)
  )
)

;; Burn function
(define-public (burn (amount uint) (owner principal))
  (begin
    (asserts! (or (is-eq tx-sender owner) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-TOKEN-OWNER)
    (ft-burn? chainchat-token amount owner)
  )
)

;; Delegation Functions

(define-map delegations principal principal)  ;; delegator -> delegatee
(define-map delegation-amounts principal uint)  ;; delegator -> amount delegated

(define-public (delegate (delegatee principal) (amount uint))
  (let (
    (delegator-balance (ft-get-balance chainchat-token tx-sender))
  )
    (asserts! (>= delegator-balance amount) ERR-INSUFFICIENT-BALANCE)
