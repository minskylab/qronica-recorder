import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'recordscreen_state.dart';

class RecordscreenCubit extends Cubit<RecordscreenState> {
  RecordscreenCubit() : super(RecordscreenInitial());
}
