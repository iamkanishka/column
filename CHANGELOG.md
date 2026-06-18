# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-06-18

### Added
- `Column.Entities` — person (KYC) and business (KYB) entity management with
  evidence upload, beneficial owner linking, and compliance narratives
- `Column.BankAccounts` — account creation, balance history, multi-owner support
- `Column.AccountNumbers` — virtual account number issuance
- `Column.Counterparties` — external party management with IBAN validation and
  financial institution lookup
- `Column.ACH` — ACH credit/debit origination (PPD/CCD/WEB/TEL/POP/IAT),
  returns, reversals, and positive pay rules
- `Column.BookTransfers` — instant internal transfers with two-phase hold support
- `Column.Wires` — domestic Fedwire transfers, drawdown requests, return request flow
- `Column.InternationalWires` — SWIFT cross-border payments, FX quote lifecycle,
  gpi tracking, amendments, cancellations
- `Column.RealtimeTransfers` — RTP and FedNow instant payments, RFP flow,
  return request flow
- `Column.Checks` — check issuance (print & mail), remote deposit capture,
  stop payments, returns
- `Column.Transfers` — unified transfer list across all payment types
- `Column.Loans` — loan origination, program management, secondary market sales
- `Column.Disbursements` — loan fund disbursements with two-phase hold
- `Column.LoanPayments` — payment collection and return handling
- `Column.Events` — immutable audit log with event type listing
- `Column.Webhooks` — endpoint management, delivery logs, HMAC signature verification
- `Column.Reporting` — settlement reports and custom bank account statements
- `Column.Documents` — file uploads for compliance submissions
- `Column.Simulation` — sandbox simulation for all payment rails
- `Column.Pagination` — cursor pagination helpers, lazy `Stream` support,
  `fetch_all/2` convenience
- `Column.Client` — HTTP layer with Basic Auth, retry + exponential backoff,
  automatic idempotency key generation, multipart upload
- `Column.Config` — runtime configuration with per-request override support
- `Column.Error` — structured error type with `:type`, `:status`, `:code`,
  `:request_id`, and `:raw` fields
