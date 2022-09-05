import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:qronica_recorder/pocketbase.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginState());

  void changeEmailAddress(String emailAddress) {
    emit(
      state.copyWith(emailAddress: emailAddress),
    );
  }
  void changePassword(String password) {
    emit(
      state.copyWith(password: password),
    );
  }


  Future<void> login() async {
    emit(
      state.copyWith(
        status: StatusLogin.loading,
      ),
    );
    try{
      final authData = await 
      PocketBaseSample.client.users.authViaEmail(state.emailAddress!,state.password!);
      print(authData.user!.id);
      PocketBaseSample.client.authStore.save(authData.token, authData.user);

      emit(
      state.copyWith(
        status: StatusLogin.success,
      ),
    );
    }
    catch(error){
      print('Error: ${error}');
    };

}
}