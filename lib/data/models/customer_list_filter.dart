enum CustomerListFilter {
  all('all', 'All'),
  active('active', 'Active Policy'),
  inactive('inactive', 'Inactive'),
  renewal('renewal', 'Renewal Due'),
  noPolicy('no-policy', 'No Policy');

  const CustomerListFilter(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
