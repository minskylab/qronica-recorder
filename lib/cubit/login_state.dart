part of 'login_cubit.dart';


enum StatusLogin { initial, loading, success, failure }
enum CurrentPage { login }


class LoginState extends Equatable {
  const LoginState({
    this.status = StatusLogin.initial,
    this.currentPage = CurrentPage.login,
    this.emailAddress,
    this.password,
  });

  final StatusLogin status;
  final CurrentPage currentPage;
  final String? emailAddress;
  final String? password;

  @override
  List<Object?> get props => [
    status,
    currentPage,
    emailAddress,
    password,
  ];

  LoginState copyWith({
    StatusLogin? status,
    CurrentPage? currentPage,
    String? emailAddress,    
    String? password,    
  }){
    return LoginState(
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      emailAddress: emailAddress ?? this.emailAddress,
      password: password ?? this.password,
    );
  }
}

