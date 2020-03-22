class ResourceRecord {
	def initialize(ip_list, type, domain) {
		@subdomain = domain
		@ip_list = ip_list
		@type = type
	}
}
