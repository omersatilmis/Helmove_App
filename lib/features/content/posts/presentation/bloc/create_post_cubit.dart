import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../media/domain/usecases/upload_image_usecase.dart';
import '../../domain/usecases/create_post_usecase.dart';
import 'create_post_state.dart';

class CreatePostCubit extends Cubit<CreatePostState> {
  final CreatePostUseCase createPost;
  final UploadImageUseCase uploadImage;

  CreatePostCubit({required this.createPost, required this.uploadImage})
    : super(const CreatePostState());

  Future<void> submitPost({
    required String text,
    required int visibility,
    String? mediaUrl,
    int type = 0, // Default type
  }) async {
    emit(state.copyWith(status: CreatePostStatus.submitting));

    String? finalMediaUrl = mediaUrl;

    // Eğer mediaUrl bir dosya yolu ise (http ile başlamıyorsa), yüklemeyi dene
    if (mediaUrl != null &&
        mediaUrl.isNotEmpty &&
        !mediaUrl.startsWith('http')) {
      final file = File(mediaUrl);
      if (file.existsSync()) {
        final uploadResult = await uploadImage(file);

        // uploadResult.fold içinde return yaparak metoddan çıkamayız,
        // bu yüzden bir değişken (uploadSuccess) veya fold'un sonucunu alıp işlemeliyiz.
        // Ancak fold, void dönerse akışı durdurmak zor.
        // En iyisi procedural bir şekilde kontrol etmek (isLeft/isRight) ama dartz buna izin vermez.
        // Şöyle yapalım:

        bool uploadFailed = false;
        String? failureMessage;

        uploadResult.fold(
          (failure) {
            uploadFailed = true;
            failureMessage = failure.message;
          },
          (url) {
            finalMediaUrl = url;
          },
        );

        if (uploadFailed) {
          emit(
            state.copyWith(
              status: CreatePostStatus.failure,
              errorMessage: failureMessage ?? 'Resim yüklenirken hata oluştu',
            ),
          );
          return;
        }
      }
    }

    final result = await createPost(
      CreatePostParams(
        text: text,
        visibility: visibility,
        mediaUrl: finalMediaUrl,
        type: type,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CreatePostStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: CreatePostStatus.success)),
    );
  }
}
