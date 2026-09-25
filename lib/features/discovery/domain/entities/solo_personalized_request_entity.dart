// Re-export of DiscoveryRequestEntity from its dedicated file.
// Tách file để mọi repository/cubit/page đều có một entry-point duy nhất,
// tránh vòng lặp import ngược giữa entity và model.
export 'discovery_request_entity.dart';
