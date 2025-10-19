import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf_viewer/feature/auth/domain/repo/repo.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Authentication Business Logic Component (BLoC)
/// 
/// Handles all authentication-related business logic including:
/// - User login
/// - User signup
/// - Authentication state management
/// 
/// This BLoC follows the Clean Architecture pattern and uses
/// the repository pattern for data abstraction.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Repository for authentication operations
  /// 
  /// This follows dependency injection principle, allowing us to
  /// easily mock or replace the authentication implementation
  final AuthRepository authRepository;

  /// Constructor initializes the BLoC with initial state and event handlers
  /// 
  /// @param authRepository - The authentication repository implementation
  /// @initialState - AuthInitial() represents the starting state
  AuthBloc(this.authRepository) : super(AuthInitial()) {
    
    /// Register event handlers for different authentication events
    
    // Handler for user login events
    on<LoginEvent>((event, emit) async {
      // Emit loading state to update UI with progress indicator
      emit(AuthLoading());
      
      try {
        // Attempt to login using provided credentials
        final user = await authRepository.login(event.email, event.password);
        
        // Log successful login (debug purposes)
        print("✓ Login successful for user: ${user?.email}");
        
        // Emit success state with user data
        emit(AuthSuccess(user));
      } catch (e) {
        // Log the error for debugging
        print("✗ Login failed: ${e.toString()}");
        
        // Emit failure state with error message
        emit(AuthFailure(e.toString()));
      }
    });

    // Handler for user registration events
    on<SignupEvent>((event, emit) async {
      // Emit loading state to show progress in UI
      emit(AuthLoading());
      
      try {
        // Attempt to create new user account
        final user = await authRepository.signup(event.email, event.password);
        
        // Log successful registration
        print("✓ Signup successful for user: ${user?.email}");
        
        // Emit success state with newly created user
        emit(AuthSuccess(user));
      } catch (e) {
        // Log the registration error
        print("✗ Signup failed: ${e.toString()}");
        
        // Emit failure state with error details
        emit(AuthFailure(e.toString()));
      }
    });
  }
}
