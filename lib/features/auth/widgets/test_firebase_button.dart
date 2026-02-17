import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stackfood_multivendor/common/widgets/custom_snackbar_widget.dart';
import 'package:get/get.dart';

/// Widget de test pour Firebase Phone Auth
/// Ajoutez ce widget temporairement dans votre écran de connexion pour tester Firebase
class TestFirebaseButton extends StatefulWidget {
  final String phoneNumber;
  
  const TestFirebaseButton({super.key, required this.phoneNumber});

  @override
  State<TestFirebaseButton> createState() => _TestFirebaseButtonState();
}

class _TestFirebaseButtonState extends State<TestFirebaseButton> {
  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;

  Future<void> _testFirebaseOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _verificationId = null;
    });

    try {
      debugPrint('🧪 TEST FIREBASE - Début du test avec: ${widget.phoneNumber}');
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('✅ TEST FIREBASE - Vérification automatique réussie');
          setState(() {
            _isLoading = false;
          });
          showCustomSnackBar('✅ Vérification automatique réussie!', isError: false);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ TEST FIREBASE - Erreur: ${e.code} - ${e.message}');
          setState(() {
            _isLoading = false;
            _errorMessage = '${e.code}: ${e.message}';
          });
          showCustomSnackBar('❌ Erreur Firebase: ${e.code} - ${e.message}', isError: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ TEST FIREBASE - Code OTP envoyé! Verification ID: $verificationId');
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
          });
          showCustomSnackBar('✅ Code OTP envoyé! Vérifiez votre téléphone.', isError: false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏱️ TEST FIREBASE - Timeout: $verificationId');
          setState(() {
            _verificationId = verificationId;
          });
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('❌ TEST FIREBASE - Exception: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      showCustomSnackBar('❌ Exception: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  '🧪 Test Firebase OTP (TEMPORAIRE)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Numéro de test: ${widget.phoneNumber}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testFirebaseOTP,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Test en cours...' : 'Tester Firebase OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_verificationId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✅ SMS envoyé!',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: $_verificationId',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '⚠️ Ce bouton est pour le test uniquement. Supprimez-le après les tests.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


