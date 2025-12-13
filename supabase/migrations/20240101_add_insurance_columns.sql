-- Add missing insurance columns to bookings table
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS has_insurance BOOLEAN DEFAULT FALSE;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS insurance_policy_number TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS insurance_provider TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS insurance_coverage_type TEXT;

-- Ensure partner_notifications table exists (used in InsuranceService)
CREATE TABLE IF NOT EXISTS partner_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  partner_id TEXT NOT NULL,
  type TEXT NOT NULL,
  claim_number TEXT,
  message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for partner_notifications if it was just created
ALTER TABLE partner_notifications ENABLE ROW LEVEL SECURITY;

-- Policy for inserting notifications (if not already exists from previous script)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'partner_notifications' AND policyname = 'Users can insert partner notifications'
    ) THEN
        CREATE POLICY "Users can insert partner notifications"
        ON partner_notifications FOR INSERT
        TO authenticated
        WITH CHECK (true);
    END IF;
END
$$;
