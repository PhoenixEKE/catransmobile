const String counterTicketPrintScope = 'station.tickets.print';

bool hasCounterTicketPrintScope(Iterable<String> scopes) {
  return scopes.contains(counterTicketPrintScope);
}

bool canPrintCounterTicket({
  required bool hasPrintScope,
  required bool backendAllowsPrint,
}) {
  return hasPrintScope && backendAllowsPrint;
}
