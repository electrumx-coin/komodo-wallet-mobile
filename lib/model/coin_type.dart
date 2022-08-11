// anchor: protocols support

enum CoinType {
  utxo,
  smartChain,
  erc,
  bep,
  plg,
  ftm,
  qrc,
  hrc,
  krc,
  etc,
  sbch,
  ubiq,
}

CoinType coinTypeFromString(String value) {
  return CoinType.values.firstWhere(
    (e) => e.name.toUpperCase() == value?.toUpperCase(),
    orElse: () => null,
  );
}
