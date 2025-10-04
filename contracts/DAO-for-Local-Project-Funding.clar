(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-voted (err u103))
(define-constant err-voting-ended (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-already-executed (err u106))
(define-constant err-quorum-not-reached (err u107))
(define-constant err-invalid-amount (err u108))

(define-data-var proposal-counter uint u0)
(define-data-var quorum-percentage uint u51)
(define-data-var voting-period uint u1440)

(define-map proposals
  uint
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    amount: uint,
    recipient: principal,
    proposer: principal,
    votes-for: uint,
    votes-against: uint,
    start-block: uint,
    end-block: uint,
    executed: bool,
    total-voters: uint
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, amount: uint }
)

(define-map member-stakes
  principal
  uint
)

(define-map members
  principal
  { joined-block: uint, active: bool }
)

(define-data-var total-staked uint u0)
(define-data-var treasury-balance uint u0)

(define-public (join-dao (stake-amount uint))
  (let
    (
      (sender tx-sender)
      (current-stake (default-to u0 (map-get? member-stakes sender)))
    )
    (asserts! (> stake-amount u0) err-invalid-amount)
    (try! (stx-transfer? stake-amount sender (as-contract tx-sender)))
    (map-set member-stakes sender (+ current-stake stake-amount))
    (map-set members sender { joined-block: stacks-block-height, active: true })
    (var-set total-staked (+ (var-get total-staked) stake-amount))
    (ok true)
  )
)

(define-public (leave-dao)
  (let
    (
      (sender tx-sender)
      (stake (default-to u0 (map-get? member-stakes sender)))
    )
    (asserts! (> stake u0) err-not-found)
    (try! (as-contract (stx-transfer? stake tx-sender sender)))
    (map-delete member-stakes sender)
    (map-set members sender { joined-block: u0, active: false })
    (var-set total-staked (- (var-get total-staked) stake))
    (ok true)
  )
)

(define-public (deposit-treasury (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set treasury-balance (+ (var-get treasury-balance) amount))
    (ok true)
  )
)

(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 500)) (amount uint) (recipient principal))
  (let
    (
      (proposal-id (+ (var-get proposal-counter) u1))
      (sender tx-sender)
      (member-stake (default-to u0 (map-get? member-stakes sender)))
    )
    (asserts! (> member-stake u0) err-unauthorized)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (<= amount (var-get treasury-balance)) err-insufficient-funds)
    (map-set proposals proposal-id
      {
        title: title,
        description: description,
        amount: amount,
        recipient: recipient,
        proposer: sender,
        votes-for: u0,
        votes-against: u0,
        start-block: stacks-block-height,
        end-block: (+ stacks-block-height (var-get voting-period)),
        executed: false,
        total-voters: u0
      }
    )
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let
    (
      (sender tx-sender)
      (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
      (member-stake (default-to u0 (map-get? member-stakes sender)))
      (existing-vote (map-get? votes { proposal-id: proposal-id, voter: sender }))
    )
    (asserts! (> member-stake u0) err-unauthorized)
    (asserts! (is-none existing-vote) err-already-voted)
    (asserts! (<= stacks-block-height (get end-block proposal)) err-voting-ended)
    (map-set votes { proposal-id: proposal-id, voter: sender } { vote: vote-for, amount: member-stake })
    (map-set proposals proposal-id
      (merge proposal
        {
          votes-for: (if vote-for (+ (get votes-for proposal) member-stake) (get votes-for proposal)),
          votes-against: (if vote-for (get votes-against proposal) (+ (get votes-against proposal) member-stake)),
          total-voters: (+ (get total-voters proposal) u1)
        }
      )
    )
    (ok true)
  )
)

(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
      (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
      (required-quorum (/ (* (var-get total-staked) (var-get quorum-percentage)) u100))
    )
    (asserts! (> stacks-block-height (get end-block proposal)) err-voting-ended)
    (asserts! (not (get executed proposal)) err-already-executed)
    (asserts! (>= total-votes required-quorum) err-quorum-not-reached)
    (asserts! (> (get votes-for proposal) (get votes-against proposal)) err-unauthorized)
    (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))
    (map-set proposals proposal-id (merge proposal { executed: true }))
    (var-set treasury-balance (- (var-get treasury-balance) (get amount proposal)))
    (ok true)
  )
)

(define-public (set-quorum-percentage (new-quorum uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (and (>= new-quorum u1) (<= new-quorum u100)) err-invalid-amount)
    (var-set quorum-percentage new-quorum)
    (ok true)
  )
)

(define-public (set-voting-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-period u0) err-invalid-amount)
    (var-set voting-period new-period)
    (ok true)
  )
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-member-stake (member principal))
  (default-to u0 (map-get? member-stakes member))
)

(define-read-only (get-member-info (member principal))
  (map-get? members member)
)

(define-read-only (get-dao-stats)
  {
    total-staked: (var-get total-staked),
    treasury-balance: (var-get treasury-balance),
    proposal-counter: (var-get proposal-counter),
    quorum-percentage: (var-get quorum-percentage),
    voting-period: (var-get voting-period)
  }
)

(define-read-only (get-proposal-status (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
      (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
      (required-quorum (/ (* (var-get total-staked) (var-get quorum-percentage)) u100))
      (is-active (<= stacks-block-height (get end-block proposal)))
      (quorum-reached (>= total-votes required-quorum))
      (passed (> (get votes-for proposal) (get votes-against proposal)))
    )
    (ok {
      is-active: is-active,
      quorum-reached: quorum-reached,
      passed: passed,
      executed: (get executed proposal),
      total-votes: total-votes,
      required-quorum: required-quorum
    })
  )
)

(define-read-only (is-member (address principal))
  (let
    ((member-info (map-get? members address)))
    (match member-info
      info (get active info)
      false
    )
  )
)

(define-read-only (can-vote (proposal-id uint) (voter principal))
  (let
    (
      (proposal (map-get? proposals proposal-id))
      (existing-vote (map-get? votes { proposal-id: proposal-id, voter: voter }))
      (member-stake (get-member-stake voter))
    )
    (match proposal
      prop (and
        (> member-stake u0)
        (is-none existing-vote)
        (<= stacks-block-height (get end-block prop))
      )
      false
    )
  )
)
