CREATE TABLE pair_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requested_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(requester_id, requested_id),
    CHECK (requester_id != requested_id),
    CHECK (status IN ('pending', 'accepted', 'rejected'))
);

CREATE INDEX idx_pair_requests_requester ON pair_requests(requester_id);
CREATE INDEX idx_pair_requests_requested ON pair_requests(requested_id);
CREATE INDEX idx_pair_requests_status ON pair_requests(status);

