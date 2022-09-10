part of 'recordscreen_cubit.dart';

enum StatusRecorder { initial, saved}


class RecordscreenState extends Equatable {
  const RecordscreenState({
    this.status = StatusRecorder.initial,
  });

  final StatusRecorder status;

  @override
  List<Object?> get props => [
    status,
  ];

  RecordscreenState copyWith({
    StatusRecorder? status,
    String? emailAddress,    
    String? password,    
  }){
    return RecordscreenState(
      status: status ?? this.status,
    );
  }
}


