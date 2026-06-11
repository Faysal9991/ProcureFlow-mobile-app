# ProcureFlow Release Readiness Checklist

Use this checklist before Android/iOS release builds.

## Startup And Auth

- App icon and splash screen are correct.
- Login succeeds with employee, manager, procurement, finance, and company admin users.
- Session expiry redirects to login without exposing raw API errors.
- Logout clears the active session and disconnects notifications.
- Change password flow works for normal and forced-password-change users.

## Role Dashboards

- Employee sees request-focused cards and actions only.
- Manager sees approvals and request context only.
- Procurement sees vendors, RFQ, purchase orders, and reports.
- Finance sees invoices, payments, budgets, and reports.
- Company admin sees all tenant modules.
- Multi-role users see the union of explicit permissions in business-process order.

## Common Workflows

- Create purchase request, save draft, submit, and cancel.
- Manager approves and rejects with validation.
- Procurement creates RFQ, assigns vendors, receives quotations, compares, and creates PO.
- PO issue, receive, close, and cancel actions work by status.
- Finance creates invoice, records payment, and verifies due/paid status.
- Budget create, activate, adjust, and close workflows work.

## Offline, Notifications, And Attachments

- Pending sync, failed sync, and synced states are visible.
- Foreground/background notifications update unread count.
- Mark read and mark all read update notifications.
- Attachments upload, open/download, share, and delete where permitted.

## UX And Stability

- Lists have loading, empty, error, refresh, and filter states.
- Details show status, sections, attachments, history, and available actions.
- Forms show clear validation errors and keyboard focus order is usable.
- App does not show raw exceptions or stack traces.
- Main screens open in under 1 second on target devices.
- Large lists scroll smoothly.

## Store Build

- Version/build number is correct.
- Firebase configuration is present for the target flavor.
- Privacy policy and terms links are ready if required by store listing.
- Crash/error monitoring is enabled for release builds if configured.
