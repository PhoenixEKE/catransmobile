const String counterTicketPrintScope = 'station.tickets.print';
const String counterSalesCashScope = 'station.sales.cash';

bool hasCounterTicketPrintScope(Iterable<String> scopes) {
  return scopes.contains(counterTicketPrintScope);
}

bool hasCounterSalesCashScope(Iterable<String> scopes) {
  return scopes.contains(counterSalesCashScope);
}

bool canPrintCounterTicket({
  required bool hasPrintScope,
  required bool backendAllowsPrint,
}) {
  return hasPrintScope && backendAllowsPrint;
}
