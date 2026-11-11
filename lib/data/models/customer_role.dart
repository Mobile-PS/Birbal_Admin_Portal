enum CustomerRole {
  customer('CUSTOMER', 'Customer'),
  sales('SALES', 'Sales'),
  operations('OPERATIONS', 'Operations'),
  companyAdmin('COMPANY_ADMIN', 'Company Admin');

  const CustomerRole(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
