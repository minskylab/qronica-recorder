import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'audioplayer_state.dart';

class AudioplayerCubit extends Cubit<AudioplayerState> {
  AudioplayerCubit() : super(AudioplayerState());

  void update(String audioPath,String audioName, int durationTotal, bool audio) {
    emit(
      state.copyWith(
        status: StatusAudioPlayer.loading,
        source: audioPath,
        sourceName: audioName,
        duration: durationTotal,
        newAudio: audio,
      ),
    );
    emit(
      state.copyWith(
        status: StatusAudioPlayer.ready,
      ),
    );
  }

  void uploading() {
        emit(
      state.copyWith(
        uploaded: StatusAudioUpload.inProgress,
      ),
    );
  }

    void uploaded() {
        emit(
      state.copyWith(
        uploaded: StatusAudioUpload.done,
      ),
    );
  }

  void notUploaded() {
            emit(
      state.copyWith(
        uploaded: StatusAudioUpload.yet,
      ),
    );
  }

  void notsaved() {
                emit(
      state.copyWith(
        uploaded: StatusAudioUpload.unsaved,
      ),
    );
  }
}
