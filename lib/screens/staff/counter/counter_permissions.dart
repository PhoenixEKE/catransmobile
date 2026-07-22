const String counterTicketPrintScope = 'station.tickets.print';
const String counterSalesCashScope = 'station.sales.cash';
const String counterDeparturesReadScope = 'station.departures.read';

bool hasCounterTicketPrintScope(Iterable<String> scopes) {
  return scopes.contains(counterTicketPrintScope);
}

bool hasCounterSalesCashScope(Iterable<String> scopes) {
  return scopes.contains(counterSalesCashScope);
}

bool hasCounterDeparturesReadScope(Iterable<String> scopes) {
  return scopes.contains(counterDeparturesReadScope);
}

bool canLoadCounterDeparturesForCashSale(Iterable<String> scopes) {
  return hasCounterSalesCashScope(scopes) &&
      hasCounterDeparturesReadScope(scopes);
}

bool canPrintCounterTicket({
  required bool hasPrintScope,
  required bool backendAllowsPrint,
}) {
  return hasPrintScope && backendAllowsPrint;
}
