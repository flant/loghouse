module Loghouse
  SUPER_DATEPICKER_PRESETS = {
    last_days: [
      { name: 'Last 2 days', from: 'now-2d', to: 'now' },
      { name: 'Last 7 days', from: 'now-7d', to: 'now' },
      { name: 'Last 30 days', from: 'now-30d', to: 'now' },
      { name: 'Last 90 days', from: 'now-90d', to: 'now' },
      { name: 'Last 6 months', from: 'now-6M', to: 'now' },
      { name: 'Last 1 year', from: 'now-1y', to: 'now' },
      { name: 'Last 2 years', from: 'now-2y', to: 'now' },
      { name: 'Last 5 years', from: 'now-5y', to: 'now' }
    ],
    last_day: [
      { name: 'Last 5 minutes', from: 'now-5m', to: 'now' },
      { name: 'Last 15 minutes', from: 'now-15m', to: 'now' },
      { name: 'Last 30 minutes', from: 'now-30m', to: 'now' },
      { name: 'Last 1 hour', from: 'now-1h', to: 'now' },
      { name: 'Last 3 hours', from: 'now-3h', to: 'now' },
      { name: 'Last 6 hours', from: 'now-6h', to: 'now' },
      { name: 'Last 12 hours', from: 'now-12h', to: 'now' },
      { name: 'Last 24 hours', from: 'now-24h', to: 'now' }
    ]
  }.freeze
end
