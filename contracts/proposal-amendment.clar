(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-voting-ended (err u104))
(define-constant err-already-executed (err u106))
(define-constant err-invalid-amount (err u108))
(define-constant err-max-amendments (err u109))

(define-map proposal-amendments
  { proposal-id: uint, amendment-id: uint }
  {
    new-title: (optional (string-ascii 100)),
    new-description: (optional (string-ascii 500)),
    new-amount: (optional uint),
    new-recipient: (optional principal),
    amended-at: uint,
    reason: (string-ascii 200)
  }
)

(define-map amendment-counters
  uint
  uint
)

(define-map vote-invalidations
  { proposal-id: uint, voter: principal }
  bool
)

(define-public (amend-proposal 
  (proposal-id uint)
  (new-title (optional (string-ascii 100)))
  (new-description (optional (string-ascii 500)))
  (new-amount (optional uint))
  (new-recipient (optional principal))
  (reason (string-ascii 200)))
  (let
    (
      (proposal (unwrap! (contract-call? .DAO-for-Local-Project-Funding get-proposal proposal-id) err-not-found))
      (amendment-count (default-to u0 (map-get? amendment-counters proposal-id)))
      (new-amendment-id (+ amendment-count u1))
    )
    (asserts! (is-eq tx-sender (get proposer proposal)) err-unauthorized)
    (asserts! (<= stacks-block-height (get end-block proposal)) err-voting-ended)
    (asserts! (not (get executed proposal)) err-already-executed)
    (asserts! (<= amendment-count u5) err-max-amendments)
    (match new-amount amount (asserts! (> amount u0) err-invalid-amount) true)
    (map-set proposal-amendments
      { proposal-id: proposal-id, amendment-id: new-amendment-id }
      {
        new-title: new-title,
        new-description: new-description,
        new-amount: new-amount,
        new-recipient: new-recipient,
        amended-at: stacks-block-height,
        reason: reason
      }
    )
    (map-set amendment-counters proposal-id new-amendment-id)
    (ok new-amendment-id)
  )
)

(define-public (invalidate-my-vote (proposal-id uint))
  (let
    ((vote (unwrap! (contract-call? .DAO-for-Local-Project-Funding get-vote proposal-id tx-sender) err-not-found)))
    (map-set vote-invalidations { proposal-id: proposal-id, voter: tx-sender } true)
    (ok true)
  )
)

(define-read-only (get-amendment (proposal-id uint) (amendment-id uint))
  (map-get? proposal-amendments { proposal-id: proposal-id, amendment-id: amendment-id })
)

(define-read-only (get-amendment-count (proposal-id uint))
  (default-to u0 (map-get? amendment-counters proposal-id))
)

(define-read-only (is-vote-invalidated (proposal-id uint) (voter principal))
  (default-to false (map-get? vote-invalidations { proposal-id: proposal-id, voter: voter }))
)
