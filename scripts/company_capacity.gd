extends RefCounted
const PER_TYPE = 3
const TOTAL = 9
const TYPES = ["mining", "exchange", "blockchain"]

static func occupies_slot(company: Variant) -> bool:
	return company is Dictionary and company.get("status", "active") != "dissolved"

static func count(companies: Array, kind: String = "") -> int:
	var result := 0
	for company in companies:
		if occupies_slot(company) and (kind.is_empty() or company.get("business", "") == kind):
			result += 1
	return result

static func can_create(companies: Array, kind: String) -> bool:
	return kind in TYPES and count(companies) < TOTAL and count(companies, kind) < PER_TYPE

static func has_capacity(companies: Array) -> bool:
	for kind in TYPES:
		if can_create(companies, kind):
			return true
	return false
