import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_app_clone_flutter/core/utils/global_var.dart';
import 'package:tiktok_app_clone_flutter/src/view/auth/login_view.dart';
import 'package:tiktok_app_clone_flutter/src/view/auth/registration_view.dart';
import 'package:tiktok_app_clone_flutter/src/view/home/home_view.dart';
import '../model/user.dart' as usermodel;

class AuthController extends GetxController {
  static AuthController instanceAuth = Get.find();

  late Rx<File?> _pickedFile = Rx<File?>(null);

  File? get profileImage => _pickedFile.value;

  late Rx<User?> _currentUser;

  void chooseImageFromGallery() async {
    final imagePickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (imagePickedFile != null) {
      Get.snackbar(
        'Profile Image',
        'You have successfully selected you profile image',
        backgroundColor: Colors.deepPurple.shade200.withOpacity(.5),
      );
    }

    _pickedFile = Rx<File?>(File(imagePickedFile!.path));
  }

  void chooseImageFromCamera() async {
    final imagePickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (imagePickedFile != null) {
      Get.snackbar(
          'Profile Image', 'You have successfully capture a profile picture');
    }

    _pickedFile = Rx<File?>(File(profileImage!.path));
  }

  void createNewAccount(
      File imageFile, String email, String username, String password) async {
    try {
      showProgressBar = true;
      //1. create user  in firebase authentication
      UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //2. save image to the firebase storage
      String imageDownloadUrl = await uploadImageToStorage(imageFile);
      //3. save user data to firestore database
      usermodel.User user = usermodel.User(
        name: username,
        email: email,
        image: imageDownloadUrl,
        uid: credential.user!.uid,
      );
      FirebaseFirestore.instance
          .collection("users")
          .doc(credential.user!.uid)
          .set(user.toJson());

      Get.snackbar(
        'Account Created',
        'Congratulation, your account has been created',
        backgroundColor: Colors.deepPurple.shade200.withOpacity(.5),
      );
      showProgressBar = false;
      Get.to(const LoginView());
    } catch (e) {
      Get.snackbar('Error Occured on Creating Account', 'Error: $e');
      showProgressBar = false;
      Get.to(const LoginView());
      throw Exception(e);
    }
  }

  Future<String> uploadImageToStorage(File imageFile) async {
    Reference reference = FirebaseStorage.instance
        .ref()
        .child("Profile Images")
        .child(FirebaseAuth.instance.currentUser!.uid);

    UploadTask uploadTask = reference.putFile(imageFile);

    TaskSnapshot taskSnapshot = await uploadTask;

    String downloadUrlOfUploadImage = await taskSnapshot.ref.getDownloadURL();

    return downloadUrlOfUploadImage;
  }

  void login(String email, String password) async {
    try {
      showProgressBar = true;
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      showProgressBar = false;
      Get.snackbar(
        'Loggen-in Successfully',
        'you are logged-in successfully',
        backgroundColor: Colors.deepPurple.shade200.withOpacity(.5),
      );
      Get.to(const RegistView());
    } catch (e) {
      Get.snackbar('Error during login', 'Error: $e');
      showProgressBar = false;
      throw Exception(e);
    }
  }

  goToScreen(User? currentUser) {
    if (currentUser == null) {
      Get.offAll(const LoginView());
    } else {
      Get.offAll(const HomeView());
    }
  }

  @override
  void onReady() {
    super.onReady();

    _currentUser = Rx<User?>(FirebaseAuth.instance.currentUser);
    _currentUser.bindStream(FirebaseAuth.instance.authStateChanges());
    ever(_currentUser, goToScreen);
  }
}
