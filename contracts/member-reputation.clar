(define-constant err-not-member (err u300))
(define-constant err-invalid-score (err u301))

(define-map member-reputation
  principal
  {
    proposal-count: uint,
    vote-count: uint,
    delegation-received: uint,
    last-activity-block: uint,
    reputation-score: uint
  }
)

(define-map activity-log
  { member: principal, block: uint }
  { activity-type: (string-ascii 20), score-change: uint }
)

(define-public (record-proposal-creation (member principal))
  (let
    (
      (current-rep (get-member-reputation member))
      (new-proposal-count (+ (get proposal-count current-rep) u1))
      (score-increase u10)
      (new-score (+ (get reputation-score current-rep) score-increase))
    )
    (asserts! (contract-call? .DAO-for-Local-Project-Funding is-member member) err-not-member)
    (map-set member-reputation member
      (merge current-rep {
        proposal-count: new-proposal-count,
        last-activity-block: stacks-block-height,
        reputation-score: new-score
      })
    )
    (map-set activity-log { member: member, block: stacks-block-height }
      { activity-type: "proposal", score-change: score-increase }
    )
    (ok true)
  )
)

(define-public (record-vote-cast (member principal))
  (let
    (
      (current-rep (get-member-reputation member))
      (new-vote-count (+ (get vote-count current-rep) u1))
      (score-increase u5)
      (new-score (+ (get reputation-score current-rep) score-increase))
    )
    (asserts! (contract-call? .DAO-for-Local-Project-Funding is-member member) err-not-member)
    (map-set member-reputation member
      (merge current-rep {
        vote-count: new-vote-count,
        last-activity-block: stacks-block-height,
        reputation-score: new-score
      })
    )
    (map-set activity-log { member: member, block: stacks-block-height }
      { activity-type: "vote", score-change: score-increase }
    )
    (ok true)
  )
)

(define-public (record-delegation-received (delegate principal))
  (let
    (
      (current-rep (get-member-reputation delegate))
      (new-delegation-count (+ (get delegation-received current-rep) u1))
      (score-increase u3)
      (new-score (+ (get reputation-score current-rep) score-increase))
    )
    (asserts! (contract-call? .DAO-for-Local-Project-Funding is-member delegate) err-not-member)
    (map-set member-reputation delegate
      (merge current-rep {
        delegation-received: new-delegation-count,
        last-activity-block: stacks-block-height,
        reputation-score: new-score
      })
    )
    (ok true)
  )
)

(define-read-only (get-member-reputation (member principal))
  (default-to
    {
      proposal-count: u0,
      vote-count: u0,
      delegation-received: u0,
      last-activity-block: u0,
      reputation-score: u0
    }
    (map-get? member-reputation member)
  )
)

(define-read-only (get-activity-log (member principal) (block uint))
  (map-get? activity-log { member: member, block: block })
)

(define-read-only (calculate-engagement-level (member principal))
  (let
    (
      (rep (get-member-reputation member))
      (total-activities (+ (+ (get proposal-count rep) (get vote-count rep)) (get delegation-received rep)))
    )
    (if (>= total-activities u20) "high"
      (if (>= total-activities u10) "medium"
        (if (>= total-activities u1) "low" "inactive")
      )
    )
  )
)