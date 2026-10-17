
// ============================================================
// SECTION A: ADMIN PANEL (FULL)
// ============================================================

class AdminPanelPage extends StatefulWidget {
  final String username;
  final String password;
  const AdminPanelPage({
    super.key,
    required this.username,
    required this.password,
  });
  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _sending = false;

  PlatformFile? _selectedFile;
  bool _uploadingFile = false;
  String? _uploadedFileUrl;
  String? _uploadedFileName;

  final _quizQuestionCtrl = TextEditingController();
  final _quizExplanationCtrl = TextEditingController();
  final _quizOptionsCtrls =
      List.generate(4, (_) => TextEditingController());
  int _quizCorrectIndex = 0;

  final _adTitleCtrl = TextEditingController();
  final _adLinkCtrl = TextEditingController();
  PlatformFile? _adImageFile;
  String? _adImageUrl;
  bool _adSaving = false;

  List<Post> _newsList = [];
  bool _loadingList = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
    _loadAdData();
  }

  Future<void> _loadNews() async {
    setState(() => _loadingList = true);
    try {
      final list =
          await ref_read_news().getNews(perPage: 20);
      if (mounted) {
        setState(() {
          _newsList = list;
          _loadingList = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  NewsRepository ref_read_news() {
    return NewsRepository(ApiClient());
  }

  void _loadAdData() {
    // Ad data is empty initially, user will set it
  }

  Future<void> _pickFile() async {
    HapticFeedback.selectionClick();
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;
      if (file.size > 50 * 1024 * 1024) {
        if (mounted) {
          showSnack(context, 'حجم فایل نباید بیش از ۵۰ مگابایت باشد.',
              error: true);
        }
        return;
      }
      setState(() {
        _selectedFile = file;
        _uploadedFileUrl = null;
        _uploadedFileName = null;
      });
    } catch (e) {
      if (mounted) showSnack(context, 'خطا: $e', error: true);
    }
  }

  void _removeFile() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFile = null;
      _uploadedFileUrl = null;
      _uploadedFileName = null;
    });
  }

  Future<bool> _uploadFileIfNeeded() async {
    if (_selectedFile == null) return true;
    if (_uploadedFileUrl != null) return true;
    if (_selectedFile!.path == null) return false;
    setState(() => _uploadingFile = true);

    try {
      final result = await AdminRepository(ApiClient()).uploadMedia(
        user: widget.username,
        pass: widget.password,
        file: File(_selectedFile!.path!),
      );

      final sourceUrl = result['source_url']?.toString() ?? '';
      if (sourceUrl.isEmpty) throw Exception('URL فایل یافت نشد');

      setState(() {
        _uploadedFileUrl = sourceUrl;
        _uploadedFileName = _selectedFile!.name;
      });
      return true;
    } catch (e) {
      if (mounted) {
        showSnack(context, e.toString(), error: true);
      }
      return false;
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
  }

  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      showSnack(context, 'عنوان و متن خبر را وارد کنید.', error: true);
      return;
    }

    setState(() => _sending = true);

    try {
      final fileOk = await _uploadFileIfNeeded();
      if (!fileOk) {
        if (mounted) setState(() => _sending = false);
        return;
      }

      String finalContent = enrichNewsContent(content);

      if (_uploadedFileUrl != null) {
        final ext =
            _uploadedFileName?.toLowerCase().split('.').last ?? '';
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
          finalContent +=
              '\n\n<img src="$_uploadedFileUrl" alt="$_uploadedFileName" style="max-width:100%;" />';
        } else {
          finalContent +=
              '\n\n<p><a href="$_uploadedFileUrl" target="_blank">دانلود فایل: $_uploadedFileName</a></p>';
        }
      }

      await AdminRepository(ApiClient()).postNews(
        user: widget.username,
        pass: widget.password,
        title: title,
        content: finalContent,
      );

      if (!mounted) return;
      showSnack(context, '✅ خبر منتشر شد!');
      _titleCtrl.clear();
      _contentCtrl.clear();
      setState(() {
        _selectedFile = null;
        _uploadedFileUrl = null;
        _uploadedFileName = null;
      });
      _loadNews();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _addQuizQuestion() async {
    final question = _quizQuestionCtrl.text.trim();
    final options =
        _quizOptionsCtrls.map((c) => c.text.trim()).toList();

    if (question.isEmpty) {
      showSnack(context, 'متن سوال را وارد کنید.', error: true);
      return;
    }
    for (int i = 0; i < options.length; i++) {
      if (options[i].isEmpty) {
        showSnack(context, 'گزینه ${i + 1} را وارد کنید.',
            error: true);
        return;
      }
    }

    setState(() => _sending = true);

    try {
      final auth = base64Encode(utf8.encode(
          '${widget.username}:${widget.password.replaceAll(' ', '')}'));
      await QuizRepository(ApiClient()).addQuestion(
        {
          'question': question,
          'options': options,
          'correctIndex': _quizCorrectIndex,
          'explanation': _quizExplanationCtrl.text.trim(),
        },
        auth,
      );

      if (!mounted) return;
      showSnack(context, '✅ سوال اضافه شد!');
      _quizQuestionCtrl.clear();
      _quizExplanationCtrl.clear();
      for (final c in _quizOptionsCtrls) {
        c.clear();
      }
      setState(() => _quizCorrectIndex = 0);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteNews(Post post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف خبر'),
        content: Text('آیا «${post.title}» حذف شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف',
                style: TextStyle(color: kUrgent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await AdminRepository(ApiClient()).deleteNews(
        user: widget.username,
        pass: widget.password,
        id: int.tryParse(post.id) ?? 0,
      );
      if (!mounted) return;
      showSnack(context, 'خبر حذف شد');
      _loadNews();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _pickAdImage() async {
    HapticFeedback.selectionClick();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;
      if (file.size > 5 * 1024 * 1024) {
        showSnack(context, 'حجم تصویر نباید بیش از ۵ مگابایت باشد.',
            error: true);
        return;
      }
      setState(() => _adImageFile = file);
    } catch (e) {
      if (mounted) showSnack(context, 'خطا: $e', error: true);
    }
  }

  Future<void> _saveAd() async {
    final title = _adTitleCtrl.text.trim();
    final link = _adLinkCtrl.text.trim();

    if (title.isEmpty && _adImageFile == null) {
      showSnack(context, 'حداقل متن یا تصویر را وارد کنید.',
          error: true);
      return;
    }

    setState(() => _adSaving = true);

    try {
      String? imageUrl = _adImageUrl;

      if (_adImageFile != null) {
        final result = await AdminRepository(ApiClient()).uploadMedia(
          user: widget.username,
          pass: widget.password,
          file: File(_adImageFile!.path!),
        );
        imageUrl = result['source_url']?.toString();
      }

      await AdRepository(ApiClient()).save(
        user: widget.username,
        pass: widget.password,
        title: title,
        link: link,
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      showSnack(context, '✅ تبلیغ ذخیره شد!');
      setState(() {
        _adImageFile = null;
        _adImageUrl = imageUrl;
      });
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _adSaving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _quizQuestionCtrl.dispose();
    _quizExplanationCtrl.dispose();
    _adTitleCtrl.dispose();
    _adLinkCtrl.dispose();
    for (final c in _quizOptionsCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Text(
            'پنل مدیریت',
            style: TextStyle(
              color: txtC,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            ),
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GlossaryAdminPage(
                      username: widget.username,
                      password: widget.password,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.translate_rounded,
                  color: Color(0xff0f766e)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding:
              EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ========== اخبار فوری ==========
              _sectionBanner(
                icon: Icons.newspaper_rounded,
                title: 'انتشار خبر فوری',
                subtitle: 'خبر با فایل ضمیمه اختیاری',
                color: kPrimaryNavy,
              ),
              const SizedBox(height: 18),
              _label('عنوان خبر'),
              const SizedBox(height: 8),
              _inputField(_titleCtrl, 'مثلاً: ثبت‌نام آغاز شد',
                  maxLines: 1, rtl: true),
              const SizedBox(height: 18),
              _label('متن کامل خبر'),
              const SizedBox(height: 8),
              _inputField(_contentCtrl, 'توضیحات کامل...',
                  maxLines: 6, rtl: true),
              const SizedBox(height: 18),
              _label('تصویر/فایل ضمیمه (اختیاری)'),
              const SizedBox(height: 8),
              if (_selectedFile == null)
                _filePickerBtn()
              else
                _selectedFileCard(),
              const SizedBox(height: 20),
              _submitBtn(
                label: _uploadingFile
                    ? 'در حال آپلود...'
                    : (_sending ? 'در حال ارسال...' : 'انتشار خبر'),
                icon: Icons.send_rounded,
                color: kPrimaryNavyLight,
                onPressed:
                    (_sending || _uploadingFile) ? null : _publish,
                loading: _sending || _uploadingFile,
              ),

              const SizedBox(height: 30),
              Divider(color: lineC),
              const SizedBox(height: 20),

              // ========== تبلیغات ==========
              _sectionBanner(
                icon: Icons.campaign_rounded,
                title: 'تبلیغات',
                subtitle: 'بنر تبلیغاتی در صفحه اصلی',
                color: kAccentGold,
              ),
              const SizedBox(height: 18),
              _label('متن تبلیغ'),
              const SizedBox(height: 8),
              _inputField(_adTitleCtrl, 'تخفیف ویژه...', rtl: true),
              const SizedBox(height: 12),
              _label('لینک تبلیغ'),
              const SizedBox(height: 8),
              _inputField(_adLinkCtrl, 'https://...', ltr: true),
              const SizedBox(height: 12),
              _label('تصویر تبلیغ'),
              const SizedBox(height: 8),
              if (_adImageFile == null && _adImageUrl == null)
                _adImagePicker()
              else if (_adImageFile != null)
                _adImageSelected()
              else
                _adImagePreview(),
              const SizedBox(height: 18),
              _submitBtn(
                label: _adSaving ? 'در حال ذخیره...' : 'ذخیره تبلیغ',
                icon: Icons.save_rounded,
                color: kAccentGold,
                onPressed: _adSaving ? null : _saveAd,
                loading: _adSaving,
              ),

              const SizedBox(height: 30),
              Divider(color: lineC),
              const SizedBox(height: 20),

              // ========== کوئیز ==========
              _sectionBanner(
                icon: Icons.quiz_rounded,
                title: 'طراحی کوئیز',
                subtitle: 'سوال چهارگزینه‌ای',
                color: kQuizColor,
              ),
              const SizedBox(height: 18),
              _label('متن سوال'),
              const SizedBox(height: 8),
              _inputField(_quizQuestionCtrl, 'متن سوال...',
                  maxLines: 3, rtl: true),
              const SizedBox(height: 16),
              _label('گزینه‌ها'),
              const SizedBox(height: 8),
              ...List.generate(4, (i) {
                final isCorrect = _quizCorrectIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? kSuccess.withOpacity(0.08)
                          : pnl,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCorrect ? kSuccess : lineC,
                        width: isCorrect ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _quizCorrectIndex = i);
                          },
                          child: Container(
                            width: 52,
                            height: 62,
                            decoration: BoxDecoration(
                              gradient: isCorrect
                                  ? const LinearGradient(
                                      colors: [
                                        kSuccess,
                                        kSuccessLight
                                      ])
                                  : null,
                              color: isCorrect
                                  ? null
                                  : pnl2,
                              borderRadius:
                                  const BorderRadius.horizontal(
                                      right: Radius.circular(13)),
                            ),
                            child: Center(
                              child: Text(
                                kQuizLetters[i],
                                style: TextStyle(
                                  color: isCorrect
                                      ? Colors.white
                                      : txtC,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _quizOptionsCtrls[i],
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: txtC,
                              fontSize: 13,
                              fontFamily: 'Vazirmatn',
                            ),
                            decoration: InputDecoration(
                              hintText: 'گزینه ${i + 1}',
                              hintStyle: TextStyle(
                                  color: mutC,
                                  fontFamily: 'Vazirmatn'),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              _label('توضیحات آموزشی (اختیاری)'),
              const SizedBox(height: 8),
              _inputField(_quizExplanationCtrl, 'توضیحات...',
                  maxLines: 3, rtl: true),
              const SizedBox(height: 18),
              _submitBtn(
                label: _sending ? 'در حال ارسال...' : 'افزودن سوال',
                icon: Icons.add_rounded,
                color: kQuizColor,
                onPressed: _sending ? null : _addQuizQuestion,
                loading: _sending,
              ),

              const SizedBox(height: 30),
              Divider(color: lineC),
              const SizedBox(height: 14),
              _label('اخبار منتشر شده'),
              const SizedBox(height: 12),

              if (_loadingList)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_newsList.isEmpty)
                Text(
                  'هنوز خبری منتشر نشده',
                  style: TextStyle(color: mutC, fontFamily: 'Vazirmatn'),
                )
              else
                ..._newsList.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: pnl,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: lineC),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: txtC,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${pDate(p)} • ${pClock(p)}',
                                  style: TextStyle(
                                    color: mutC,
                                    fontSize: 10.5,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteNews(p),
                            icon: Icon(Icons.delete_outline_rounded,
                                color: rose, size: 22),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: mutC,
                    fontSize: 10.5,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          color: txtC,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          fontFamily: 'Vazirmatn',
        ),
      );

  Widget _inputField(
    TextEditingController c,
    String hint, {
    int maxLines = 1,
    bool rtl = false,
    bool ltr = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineC),
      ),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        textDirection:
            ltr ? TextDirection.ltr : TextDirection.rtl,
        textAlign: ltr ? TextAlign.left : TextAlign.right,
        style: TextStyle(
            color: txtC, fontSize: 13.5, fontFamily: 'Vazirmatn'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: mutC, fontFamily: 'Vazirmatn'),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _filePickerBtn() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: accentNotifier.value.withOpacity(0.4),
              width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accentNotifier.value,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_file_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              'انتخاب فایل',
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            Text(
              'حداکثر ۵۰ مگابایت',
              style: TextStyle(
                color: mutC,
                fontSize: 11,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedFileCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSuccess, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kSuccess,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.insert_drive_file_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedFile!.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: txtC,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
          GestureDetector(
            onTap: _removeFile,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rose.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.close_rounded, color: rose, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adImagePicker() {
    return GestureDetector(
      onTap: _pickAdImage,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kAccentGold.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: kAccentGold.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: kAccentGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_photo_alternate_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              'انتخاب تصویر',
              style: TextStyle(
                color: txtC,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adImageSelected() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAccentGold),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kAccentGold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _adImageFile!.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: txtC,
                fontSize: 12.5,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _adImageFile = null),
            child: Icon(Icons.close_rounded, color: rose, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _adImagePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kSuccess),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: kSuccess, size: 24),
          const SizedBox(width: 10),
          Text(
            'تصویر فعلی تنظیم شده',
            style: TextStyle(
              color: kSuccess,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION B: GLOSSARY ADMIN PAGE
// ============================================================

class GlossaryAdminPage extends StatefulWidget {
  final String username;
  final String password;
  const GlossaryAdminPage({
    super.key,
    required this.username,
    required this.password,
  });

  @override
  State<GlossaryAdminPage> createState() => _GlossaryAdminPageState();
}

class _GlossaryAdminPageState extends State<GlossaryAdminPage> {
  final _enCtrl = TextEditingController();
  final _faCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<dynamic> _items = [];
  bool _loading = true;
  bool _sending = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _enCtrl.dispose();
    _faCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await GlossaryRepository(ApiClient()).getAll(force: true);
      if (mounted) {
        setState(() {
          _items = list.map((w) => w.toMap()).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _basicAuth() {
    final clean = widget.password.replaceAll(' ', '');
    return base64Encode(utf8.encode('${widget.username}:$clean'));
  }

  Future<void> _submit() async {
    final en = _enCtrl.text.trim();
    final fa = _faCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (en.isEmpty || fa.isEmpty) {
      showSnack(context, 'کلمه انگلیسی و فارسی را وارد کنید.',
          error: true);
      return;
    }

    setState(() => _sending = true);

    try {
      final auth = _basicAuth();
      if (_editingId != null) {
        await ApiClient().put(
          '${Env.glossaryApi}/$_editingId',
          {'en': en, 'fa': fa, 'desc': desc},
          headers: {'Authorization': 'Basic $auth'},
        );
        if (!mounted) return;
        showSnack(context, '✅ لغت ویرایش شد!');
      } else {
        await ApiClient().post(
          Env.glossaryApi,
          {'en': en, 'fa': fa, 'desc': desc},
          headers: {'Authorization': 'Basic $auth'},
        );
        if (!mounted) return;
        showSnack(context, '✅ لغت اضافه شد!');
      }

      _enCtrl.clear();
      _faCtrl.clear();
      _descCtrl.clear();
      setState(() => _editingId = null);
      await _load();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(dynamic item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pnl,
        title: const Text('حذف لغت'),
        content: Text('آیا «${item['en']}» حذف شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف',
                style: TextStyle(color: kUrgent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiClient().delete(
        '${Env.glossaryApi}/$id',
        headers: {'Authorization': 'Basic ${_basicAuth()}'},
      );
      if (mounted) {
        showSnack(context, 'لغت حذف شد');
        await _load();
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  void _startEdit(dynamic item) {
    HapticFeedback.selectionClick();
    setState(() {
      _editingId = item['id']?.toString();
      _enCtrl.text = item['en']?.toString() ?? '';
      _faCtrl.text = item['fa']?.toString() ?? '';
      _descCtrl.text = item['desc']?.toString() ?? '';
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _enCtrl.clear();
      _faCtrl.clear();
      _descCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xff0f766e),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.translate_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'مدیریت لغات',
                style: TextStyle(
                  color: txtC,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded,
                  color: Color(0xff0f766e)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_editingId != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: kWarning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: kWarning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          color: kWarning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'در حال ویرایش',
                          style: TextStyle(
                            color: kWarning,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _cancelEdit,
                        child: Text('لغو',
                            style: TextStyle(
                                color: kWarning,
                                fontFamily: 'Vazirmatn')),
                      ),
                    ],
                  ),
                ),
              Text('کلمه انگلیسی',
                  style: TextStyle(
                    color: txtC,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  )),
              const SizedBox(height: 8),
              _field(_enCtrl, 'Aerobic', ltr: true),
              const SizedBox(height: 14),
              Text('معادل فارسی',
                  style: TextStyle(
                    color: txtC,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  )),
              const SizedBox(height: 8),
              _field(_faCtrl, 'هوازی', rtl: true),
              const SizedBox(height: 14),
              Text('توضیحات',
                  style: TextStyle(
                    color: txtC,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  )),
              const SizedBox(height: 8),
              _field(_descCtrl, 'توضیح کوتاه...', rtl: true, maxLines: 3),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0f766e),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_editingId != null
                          ? Icons.save_rounded
                          : Icons.add_rounded),
                  label: Text(
                    _editingId != null ? 'ذخیره' : 'افزودن لغت',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Divider(color: lineC),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.list_alt_rounded,
                      color: const Color(0xff0f766e), size: 18),
                  const SizedBox(width: 8),
                  Text('لغات موجود (${_items.length})',
                      style: TextStyle(
                        color: txtC,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      )),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_items.isEmpty)
                Text('هنوز لغتی اضافه نشده',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: mutC, fontFamily: 'Vazirmatn'))
              else
                ..._items.map((item) => _itemCard(item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {bool rtl = false, bool ltr = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineC),
      ),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        textDirection:
            ltr ? TextDirection.ltr : TextDirection.rtl,
        textAlign: ltr ? TextAlign.left : TextAlign.right,
        style: TextStyle(
            color: txtC, fontSize: 13.5, fontFamily: 'Vazirmatn'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: mutC, fontFamily: 'Vazirmatn'),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _itemCard(dynamic item) {
    final en = item['en']?.toString() ?? '';
    final fa = item['fa']?.toString() ?? '';
    final desc = item['desc']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xff0f766e).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(en,
                    style: const TextStyle(
                      color: Color(0xff0f766e),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(fa,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: txtC,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    )),
              ),
              IconButton(
                onPressed: () => _startEdit(item),
                icon: const Icon(Icons.edit_rounded,
                    color: Color(0xff0f766e), size: 20),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _delete(item),
                icon: Icon(Icons.delete_outline_rounded,
                    color: rose, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: mutC,
                  fontSize: 11.5,
                  height: 1.7,
                  fontFamily: 'Vazirmatn',
                )),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// SECTION C: NOTIFICATIONS PAGE
// ============================================================

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});
  @override
  ConsumerState<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _loading = true);
    try {
      await _checkForNewNotifications();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final list = await ref.read(newsRepoProvider).getNews(perPage: 20);
      if (list.isEmpty) return;

      final existing = ref.read(notificationsProvider);
      final existingIds = existing.map((e) => e.id).toSet();

      final now = DateTime.now();
      final newOnes = <AppNotification>[];

      for (final news in list) {
        if (existingIds.contains(news.id)) continue;

        newOnes.add(AppNotification(
          id: news.id,
          title: news.title,
          excerpt: news.excerpt.length > 100
              ? '${news.excerpt.substring(0, 100)}...'
              : news.excerpt,
          link: news.link,
          image: news.image ?? '',
          date: news.date,
          read: false,
          createdAt: now,
        ));
      }

      if (newOnes.isNotEmpty) {
        await ref.read(notificationsProvider.notifier).addAll(newOnes);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unread =
        notifications.where((e) => !e.read).length;

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kSuccess,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اعلان‌ها',
                    style: TextStyle(
                      color: txtC,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  if (unread > 0)
                    Text(
                      '$unread جدید',
                      style: const TextStyle(
                        color: kUrgent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                ],
              ),
            ],
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
          actions: [
            if (notifications.isNotEmpty) ...[
              IconButton(
                tooltip: 'خوانده‌شده کردن همه',
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await ref
                      .read(notificationsProvider.notifier)
                      .markAllRead();
                  if (mounted) {
                    showSnack(context, 'همه خوانده شد');
                  }
                },
                icon: Icon(Icons.done_all_rounded,
                    color: accentNotifier.value, size: 22),
              ),
              IconButton(
                tooltip: 'حذف همه',
                onPressed: () => _confirmClear(context),
                icon: Icon(Icons.delete_sweep_rounded,
                    color: rose, size: 22),
              ),
            ],
          ],
        ),
        body: _loading
            ? const SearchSkeletonPlaceholder()
            : notifications.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    color: kSuccess,
                    backgroundColor: pnl,
                    onRefresh: _check,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          14, 14, 14, 100),
                      itemCount: notifications.length,
                      itemBuilder: (c, i) =>
                          _notificationCard(notifications[i]),
                    ),
                  ),
      ),
    );
  }

  Widget _notificationCard(AppNotification n) {
    final isRead = n.read;
    final timeAgo = pTimeAgo({'date': n.date.toIso8601String()});

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await ref.read(notificationsProvider.notifier).markRead(n.id);
        if (!mounted) return;

        // تلاش برای دریافت خبر کامل
        try {
          final segs = n.link.split('/').where((s) => s.isNotEmpty).toList();
          if (segs.isNotEmpty) {
            final slug = segs.last;
            final url =
                '${Env.api}/new_news?slug=${Uri.encodeComponent(slug)}'
                '&_embed=wp:featuredmedia,wp:term,author';
            final r = await http
                .get(Uri.parse(url))
                .timeout(const Duration(seconds: 8));
            if (r.statusCode == 200) {
              final list = json.decode(r.body) as List;
              if (list.isNotEmpty && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UrgentNewsDetailPage(news: list.first),
                  ),
                );
                return;
              }
            }
          }
        } catch (_) {}

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UrgentNewsDetailPage(
              news: {
                'id': n.id,
                'title': {'rendered': n.title},
                'content': {'rendered': n.excerpt},
                'link': n.link,
                'date': n.date.toIso8601String(),
                if (n.image.isNotEmpty)
                  '_embedded': {
                    'wp:featuredmedia': [
                      {'source_url': n.image}
                    ],
                  },
              },
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: !isRead
              ? LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    kSuccess.withOpacity(0.10),
                    kSuccess.withOpacity(0.02),
                  ],
                )
              : null,
          color: isRead ? pnl : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !isRead
                ? kSuccess.withOpacity(0.35)
                : lineC,
            width: !isRead ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: pnl2,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: n.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: n.image,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
                            placeholder: (_, __) =>
                                Container(color: pnl2),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.newspaper_rounded,
                              color: mutC,
                              size: 24,
                            ),
                          )
                        : Icon(
                            Icons.newspaper_rounded,
                            color: mutC,
                            size: 24,
                          ),
                  ),
                ),
                if (!isRead)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: kUrgent,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgC, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: txtC,
                      fontSize: 13,
                      fontWeight:
                          isRead ? FontWeight.w700 : FontWeight.w900,
                      height: 1.5,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  if (n.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      n.excerpt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: mutC,
                        fontSize: 11,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          color: mutC, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: mutC,
                          fontSize: 10,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kSuccess.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                color: kSuccess,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'اعلان جدیدی ندارید',
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'خبرهای فوری جدید در اینجا نمایش داده می‌شود',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutC,
                fontSize: 12,
                height: 1.7,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pnl,
        title: Text('حذف همه اعلان‌ها',
            style: TextStyle(
              color: txtC,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            )),
        content: Text('آیا همه اعلان‌ها حذف شوند؟',
            style: TextStyle(color: mutC, fontFamily: 'Vazirmatn')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف',
                style: TextStyle(color: kUrgent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(notificationsProvider.notifier).clear();
      if (context.mounted) showSnack(context, 'همه اعلان‌ها حذف شد');
    }
  }
}

// placeholder برای اسکلتون در اعلان‌ها
class SearchSkeletonPlaceholder extends StatelessWidget {
  const SearchSkeletonPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pnl,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: lineC),
            ),
            child: Row(
              children: const [
                ShimmerBox(height: 56, width: 56, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 12),
                      SizedBox(height: 6),
                      ShimmerBox(height: 12, width: 140),
                      SizedBox(height: 6),
                      ShimmerBox(height: 10, width: 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION D: FOLLOWED CATEGORIES PAGE + ALL CATEGORIES PAGE
// ============================================================

// ---------- FOLLOWED CATEGORIES PAGE ----------

class FollowedCategoriesPage extends ConsumerWidget {
  const FollowedCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(followedCategoriesProvider);
    final followedCats =
        cats.where((cat) => followed.contains(cat.s)).toList();

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryNavy, kAccentGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'دسته‌بندی‌های من',
                style: TextStyle(
                  color: txtC,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
          actions: [
            if (followed.isNotEmpty)
              IconButton(
                tooltip: 'پاک کردن همه',
                onPressed: () => _confirmClear(context, ref),
                icon: Icon(Icons.delete_sweep_rounded,
                    color: rose, size: 22),
              ),
          ],
        ),
        body: followedCats.isEmpty
            ? _buildEmptyState(context, ref)
            : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kPrimaryNavy.withOpacity(0.12),
                          kAccentGold.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: kPrimaryNavy.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kPrimaryNavy, kAccentGold],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.favorite_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${followed.length} دسته‌بندی دنبال می‌شود',
                            style: TextStyle(
                              color: txtC,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AllCategoriesPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: kPrimaryNavy.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    color: kPrimaryNavy, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'افزودن',
                                  style: TextStyle(
                                    color: kPrimaryNavy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(14, 0, 14, 100),
                      itemCount: followedCats.length,
                      itemBuilder: (c, i) =>
                          _categoryCard(context, ref, followedCats[i]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _categoryCard(BuildContext context, WidgetRef ref, Cat cat) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryPostsPage(c: cat),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              cat.c.withOpacity(0.15),
              cat.c.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cat.c.withOpacity(0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cat.c, cat.c.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(cat.i, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cat.n,
                style: TextStyle(
                  color: txtC,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1.5,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                ref
                    .read(followedCategoriesProvider.notifier)
                    .toggle(cat.s);
                showSnack(context, 'لغو دنبال کردن «${cat.n}»');
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rose.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: rose.withOpacity(0.3)),
                ),
                child: Icon(Icons.close_rounded,
                    color: rose, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kAccentGold.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: kAccentGold,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'هنوز دسته‌ای دنبال نمی‌کنید',
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'با زدن دکمه زیر، از لیست دسته‌ها آن‌هایی که\nموردعلاقه‌تان است را دنبال کنید',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutC,
                fontSize: 12,
                height: 1.7,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AllCategoriesPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryNavy, kAccentGold],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'انتخاب دسته‌بندی',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pnl,
        title: Text('لغو دنبال کردن همه',
            style: TextStyle(
              color: txtC,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            )),
        content: Text('آیا همه حذف شوند؟',
            style: TextStyle(color: mutC, fontFamily: 'Vazirmatn')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('پاک کن',
                style: TextStyle(color: kUrgent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(followedCategoriesProvider.notifier).clear();
      if (context.mounted) showSnack(context, 'همه حذف شد');
    }
  }
}

// ---------- ALL CATEGORIES PAGE ----------

class AllCategoriesPage extends ConsumerWidget {
  const AllCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryNavy, kAccentGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grid_view_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'همه دسته‌بندی‌ها',
                style: TextStyle(
                  color: txtC,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          child: Column(
            children: cats.map((cat) {
              final followed =
                  ref.watch(followedCategoriesProvider).contains(cat.s);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryPostsPage(c: cat),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: pnl,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: followed ? cat.c : lineC,
                      width: followed ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cat.c.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(cat.i, color: cat.c, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat.n,
                          style: TextStyle(
                            color: txtC,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.5,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          ref
                              .read(followedCategoriesProvider.notifier)
                              .toggle(cat.s);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: followed
                                ? LinearGradient(
                                    colors: [
                                      cat.c,
                                      cat.c.withOpacity(0.7)
                                    ],
                                  )
                                : null,
                            color: followed
                                ? null
                                : cat.c.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            followed
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            color: followed ? Colors.white : cat.c,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION E: QUIZ PAGE (FULL)
// ============================================================

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});
  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _showResult = false;
  bool _refreshing = false;
  bool _isFetching = false;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToFirstUnanswered();
    });
    _autoRefresh = Timer.periodic(const Duration(seconds: 30), (t) {
      if (mounted && !_refreshing && !_isFetching) _silentRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _silentRefresh();
    }
  }

  Future<void> _silentRefresh() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      await ref.read(quizRepoProvider).getQuestions(force: true);
      if (mounted) ref.invalidate(quizProvider);
    } catch (_) {} finally {
      _isFetching = false;
    }
  }

  Future<void> _manualRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _refreshing = true);
    await _silentRefresh();
    if (mounted) {
      setState(() => _refreshing = false);
      showSnack(context, 'سوالات به‌روز شد ✅');
    }
  }

  void _jumpToFirstUnanswered() {
    final quizAsync = ref.read(quizProvider);
    final questions = quizAsync.valueOrNull;
    if (questions == null || questions.isEmpty) return;

    final answers = ref.read(quizAnswersProvider);
    for (int i = 0; i < questions.length; i++) {
      if (!answers.containsKey(questions[i].id)) {
        if (mounted) setState(() => _currentIndex = i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider);
    final answers = ref.watch(quizAnswersProvider);

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kQuizColor, kAccentGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.quiz_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'کوئیز ورزشی',
                style: TextStyle(
                  color: txtC,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _refreshing ? null : _manualRefresh,
              icon: _refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kQuizColor),
                    )
                  : Icon(Icons.refresh_rounded,
                      color: kQuizColor, size: 22),
            ),
            quizAsync.valueOrNull != null &&
                    quizAsync.valueOrNull!.isNotEmpty
                ? TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showResult = !_showResult);
                    },
                    icon: Icon(
                      _showResult
                          ? Icons.list_alt_rounded
                          : Icons.bar_chart_rounded,
                      color: kQuizColor,
                      size: 18,
                    ),
                    label: Text(
                      _showResult ? 'سوالات' : 'نتیجه',
                      style: TextStyle(
                        color: kQuizColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        body: quizAsync.when(
          data: (questions) {
            if (questions.isEmpty) return _buildEmpty();
            if (_showResult) {
              return _buildResult(questions, answers);
            }
            return _buildQuestionList(questions, answers);
          },
          loading: () => const Center(
              child: CircularProgressIndicator()),
          error: (e, _) => ErrorBox(
            message: 'خطا: $e',
            onRetry: () => ref.invalidate(quizProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kQuizColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.quiz_outlined,
                  color: kQuizColor, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'هنوز سوالی ثبت نشده',
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionList(
    List<QuizQuestion> questions,
    Map<String, int> answers,
  ) {
    if (_currentIndex >= questions.length) {
      _currentIndex = questions.length - 1;
    }

    final answeredCount =
        questions.where((q) => answers.containsKey(q.id)).length;
    final q = questions[_currentIndex];
    final savedAnswer = answers[q.id];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Column(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: lineC,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor:
                      (_currentIndex + 1) / questions.length,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kQuizColor, kAccentGold],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kQuizColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'سوال ${_currentIndex + 1} از ${questions.length}',
                      style: const TextStyle(
                        color: kQuizColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kSuccess.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'پاسخ‌داده: $answeredCount',
                      style: const TextStyle(
                        color: kSuccess,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: pnl,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: savedAnswer != null
                          ? kSuccess.withOpacity(0.4)
                          : kQuizColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    q.question,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: txtC,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.8,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(q.options.length, (i) {
                  final isAnswered = savedAnswer != null;
                  final isCorrect = i == q.correctIndex;
                  final isSelected = i == savedAnswer;

                  Color bg;
                  Color border;
                  Color text;
                  if (!isAnswered) {
                    bg = pnl;
                    border = lineC;
                    text = txtC;
                  } else if (isCorrect) {
                    bg = kSuccess.withOpacity(0.15);
                    border = kSuccess;
                    text = kSuccess;
                  } else if (isSelected) {
                    bg = kUrgent.withOpacity(0.15);
                    border = kUrgent;
                    text = kUrgent;
                  } else {
                    bg = pnl;
                    border = lineC;
                    text = mutC;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: isAnswered
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              await ref
                                  .read(quizAnswersProvider.notifier)
                                  .save(q.id, i);
                            },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: border, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: kQuizColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  kQuizLetters[i],
                                  style: const TextStyle(
                                    color: kQuizColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                q.options[i],
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.6,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                            if (isAnswered &&
                                (isCorrect || isSelected))
                              Icon(
                                isCorrect
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: isCorrect ? kSuccess : kUrgent,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (savedAnswer != null) ...[
                  const SizedBox(height: 16),
                  _buildFeedback(q, savedAnswer),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (_currentIndex > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _currentIndex--),
                          icon: const Icon(Icons.arrow_forward_rounded,
                              size: 18),
                          label: const Text('قبلی'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kQuizColor,
                            side: BorderSide(color: kQuizColor),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    if (_currentIndex > 0) const SizedBox(width: 10),
                    if (_currentIndex < questions.length - 1)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _currentIndex++),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kQuizColor,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded,
                              size: 18),
                          label: const Text('بعدی'),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(
                              () => _showResult = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.bar_chart_rounded,
                              size: 18),
                          label: const Text('مشاهده نتیجه'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedback(QuizQuestion q, int selectedIndex) {
    final isCorrect = selectedIndex == q.correctIndex;
    final feedbackColor = isCorrect ? kSuccess : kUrgent;
    final correctLetter =
        kQuizLetters[q.correctIndex % kQuizLetters.length];

    return Container(
      decoration: BoxDecoration(
        color: feedbackColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: feedbackColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: feedbackColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCorrect
                      ? Icons.celebration_rounded
                      : Icons.sentiment_dissatisfied_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCorrect
                        ? 'آفرین! پاسخ درست بود 🎉'
                        : 'متأسفانه پاسخ اشتباه بود',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: kSuccess.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'پاسخ صحیح: گزینه «$correctLetter»',
                        style: const TextStyle(
                          color: kSuccess,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q.options[q.correctIndex],
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: txtC,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
                if (q.explanation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kInfo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: kInfo.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_rounded,
                                color: kInfo, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'توضیحات آموزشی',
                              style: TextStyle(
                                color: kInfo,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.explanation,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: txtC,
                            fontSize: 13,
                            height: 1.9,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(
    List<QuizQuestion> questions,
    Map<String, int> answers,
  ) {
    final total = questions.length;
    final answered =
        questions.where((q) => answers.containsKey(q.id)).length;
    final correct = questions.where((q) {
      final ans = answers[q.id];
      return ans != null && ans == q.correctIndex;
    }).length;
    final wrong = answered - correct;
    final percent = total > 0 ? (correct / total * 100).round() : 0;
    final unanswered = total - answered;

    Color resultColor;
    String resultText;
    IconData resultIcon;
    String motivationalText;

    if (answered == 0) {
      resultColor = kQuizColor;
      resultText = 'هنوز شروع نکردی';
      resultIcon = Icons.play_circle_rounded;
      motivationalText = 'برای دیدن نتیجه، به سوالات پاسخ بده';
    } else if (percent >= 80) {
      resultColor = kSuccess;
      resultText = 'عالی بود! 🎉';
      resultIcon = Icons.emoji_events_rounded;
      motivationalText = 'دانش ورزشی شما فوق‌العاده است';
    } else if (percent >= 50) {
      resultColor = kWarning;
      resultText = 'خوب بود! 👍';
      resultIcon = Icons.thumb_up_rounded;
      motivationalText = 'با کمی تمرین بیشتر، بهتر می‌شی';
    } else {
      resultColor = kUrgent;
      resultText = 'نیاز به تمرین بیشتر';
      resultIcon = Icons.school_rounded;
      motivationalText = 'با مرور توضیحات بهتر می‌شی';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 100),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  resultColor.withOpacity(0.15),
                  resultColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: resultColor.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: resultColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(resultIcon,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  resultText,
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  motivationalText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutC,
                    fontSize: 12,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: pnl,
                    shape: BoxShape.circle,
                    border: Border.all(color: resultColor, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent٪',
                        style: TextStyle(
                          color: resultColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      Text('امتیاز',
                          style: TextStyle(
                              color: mutC,
                              fontSize: 11,
                              fontFamily: 'Vazirmatn')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  Icons.list_alt_rounded,
                  'کل',
                  '$total',
                  kQuizColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  Icons.edit_note_rounded,
                  'پاسخ‌داده',
                  '$answered',
                  kInfo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  Icons.check_circle_rounded,
                  'صحیح',
                  '$correct',
                  kSuccess,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  Icons.cancel_rounded,
                  'اشتباه',
                  '$wrong',
                  kUrgent,
                ),
              ),
            ],
          ),
          if (unanswered > 0) ...[
            const SizedBox(height: 10),
            _statCard(
              Icons.pending_actions_rounded,
              'بدون پاسخ',
              '$unanswered',
              kWarning,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                int firstUnanswered = 0;
                bool found = false;
                for (int i = 0; i < questions.length; i++) {
                  if (!answers.containsKey(questions[i].id)) {
                    firstUnanswered = i;
                    found = true;
                    break;
                  }
                }
                setState(() {
                  _currentIndex = found ? firstUnanswered : 0;
                  _showResult = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kQuizColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                unanswered > 0
                    ? Icons.play_arrow_rounded
                    : Icons.list_alt_rounded,
                size: 20,
              ),
              label: Text(
                unanswered > 0
                    ? 'ادامه پاسخ‌دهی'
                    : 'مشاهده سوالات',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineC),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: mutC,
                    fontSize: 11,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION F: READING STATS PAGE (FULL)
// ============================================================

class ReadingStatsPage extends ConsumerWidget {
  const ReadingStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(readingStatsProvider);

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kSuccess, kSuccessLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.insights_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'آمار مطالعه',
                style: TextStyle(
                  color: txtC,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
          actions: [
            if (stats.totalRead > 0)
              IconButton(
                tooltip: 'پاک کردن آمار',
                onPressed: () => _confirmClear(context, ref),
                icon: Icon(Icons.delete_sweep_rounded,
                    color: rose, size: 22),
              ),
          ],
        ),
        body: stats.totalRead == 0
            ? _buildEmpty()
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStreakCard(stats.streak),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.article_rounded,
                            label: 'کل مقالات',
                            value: '${stats.totalRead}',
                            color: kPrimaryNavyLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.calendar_today_rounded,
                            label: 'این هفته',
                            value: '${stats.weekCount}',
                            color: kTabShop,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.date_range_rounded,
                            label: 'این ماه',
                            value: '${stats.monthCount}',
                            color: kTabArticles,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.access_time_rounded,
                            label: 'زمان کل (دقیقه)',
                            value: '${stats.totalReadTime}',
                            color: kSuccess,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildWeeklyChart(stats.dailyCount),
                    const SizedBox(height: 14),
                    if (stats.categoryCount.isNotEmpty)
                      _buildTopCategories(stats.categoryCount),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            kTabShop.withOpacity(0.15),
            kTabShop.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kTabShop.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kTabShop, kAccentGold],
              ),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'روزهای پیوسته',
                  style: TextStyle(
                    color: mutC,
                    fontSize: 12,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        color: kTabShop,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.only(bottom: 6, right: 4),
                      child: Text(
                        'روز',
                        style: TextStyle(
                          color: kTabShop,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: txtC,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: mutC,
              fontSize: 11,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(Map<String, int> dailyCount) {
    final now = DateTime.now();
    final days = <Map<String, dynamic>>[];
    int maxCount = 1;

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      final count = dailyCount[key] ?? 0;
      if (count > maxCount) maxCount = count;
      days.add({
        'label': _getDayLabel(day.weekday),
        'count': count,
        'isToday': i == 0,
      });
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: kSuccess,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.bar_chart_rounded,
                  color: kSuccess, size: 18),
              const SizedBox(width: 6),
              Text(
                'مطالعه هفته گذشته',
                style: TextStyle(
                  color: txtC,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final count = d['count'] as int;
                final isToday = d['isToday'] as bool;
                final heightPercent = maxCount > 0
                    ? (count / maxCount).clamp(0.1, 1.0)
                    : 0.1;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: count > 0 ? kSuccess : mutC,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 28,
                      height: 100 * heightPercent,
                      decoration: BoxDecoration(
                        gradient: count > 0
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isToday
                                    ? [kTabShop, kAccentGold]
                                    : [kSuccess, kSuccessLight],
                              )
                            : null,
                        color: count == 0
                            ? lineC.withOpacity(0.5)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d['label'] as String,
                      style: TextStyle(
                        color: isToday ? kTabShop : mutC,
                        fontSize: 10.5,
                        fontWeight: isToday
                            ? FontWeight.w900
                            : FontWeight.w700,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(int weekday) {
    const days = ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'];
    return days[(weekday - 1) % 7];
  }

  Widget _buildTopCategories(Map<String, int> categoryCount) {
    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final maxVal = top.isNotEmpty ? top.first.value : 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: kTabArticles,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.trending_up_rounded,
                  color: kTabArticles, size: 18),
              const SizedBox(width: 6),
              Text(
                'دسته‌های موردعلاقه شما',
                style: TextStyle(
                  color: txtC,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...top.map((entry) {
            final percent = maxVal > 0 ? entry.value / maxVal : 0.0;
            final cat = cats.firstWhere(
              (c) => c.n == entry.key,
              orElse: () => const Cat('سایر', 'other',
                  Icons.category_rounded, Color(0xff6b7280)),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cat.c.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child:
                            Icon(cat.i, color: cat.c, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: txtC,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          color: cat.c,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 6,
                      color: lineC,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerRight,
                        widthFactor: percent,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cat.c,
                                cat.c.withOpacity(0.7)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kSuccess.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: kSuccess,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'هنوز آماری وجود ندارد',
              style: TextStyle(
                color: txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'با خواندن مقالات، آمار مطالعه شما اینجا نمایش داده می‌شود',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutC,
                fontSize: 12,
                height: 1.7,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pnl,
        title: Text('پاک کردن آمار',
            style: TextStyle(
              color: txtC,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            )),
        content: Text('آیا همه آمار مطالعه پاک شود؟',
            style: TextStyle(color: mutC, fontFamily: 'Vazirmatn')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('پاک کن',
                style: TextStyle(color: kUrgent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(readingStatsProvider.notifier).clearAll();
      if (context.mounted) showSnack(context, 'آمار پاک شد');
    }
  }
}

// ============================================================
// SECTION G: HOME WIDGETS (Carousel + AdBanner + NewsBanner + Followed)
// ============================================================

// ---------- HERO CAROUSEL ----------

class HeroCarousel extends StatefulWidget {
  final Future<List<Post>>? postsFuture;
  const HeroCarousel({super.key, required this.postsFuture});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late final PageController _pageCtrl = PageController(
    viewportFraction: 0.92,
  );
  Timer? _timer;
  Timer? _progressTimer;
  int _current = 0;
  int _count = 0;
  double _autoProgress = 0;

  @override
  void didUpdateWidget(covariant HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postsFuture != widget.postsFuture) {
      _timer?.cancel();
      _timer = null;
      _progressTimer?.cancel();
      _autoProgress = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startAuto(int count) {
    _timer?.cancel();
    _progressTimer?.cancel();
    if (count <= 1) return;

    _progressTimer = Timer.periodic(
        const Duration(milliseconds: 50), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _autoProgress += 0.01;
        if (_autoProgress >= 1.0) _autoProgress = 0;
      });
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final next = (_current + 1) % count.clamp(1, 1000);
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _autoProgress = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: widget.postsFuture,
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return Container(
            height: R.w(260),
            margin: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            decoration: BoxDecoration(
              color: pnl,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: lineC),
            ),
            child: ShimmerBox(height: R.w(260), radius: 22),
          );
        }
        final posts = (s.data ?? []).take(5).toList();
        if (posts.isEmpty) {
          return const SizedBox.shrink();
        }
        _count = posts.length;
        if (_timer == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startAuto(_count);
          });
        }

        return Container(
          margin: const EdgeInsets.only(top: 14, bottom: 6),
          child: Column(
            children: [
              SizedBox(
                height: R.w(260),
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: (i) {
                    setState(() {
                      _current = i;
                      _autoProgress = 0;
                    });
                  },
                  itemCount: posts.length,
                  itemBuilder: (c, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _CarouselCard(
                      post: posts[i],
                      isActive: i == _current,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildDots(posts.length),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == _current;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _pageCtrl.animateToPage(
              i,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 30 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? kAccentGold : mutC.withOpacity(0.25),
              borderRadius: BorderRadius.circular(999),
            ),
            child: active
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: _autoProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.9),
                                  kAccentGoldLight,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }
}

// ---------- CAROUSEL CARD ----------

class _CarouselCard extends StatefulWidget {
  final Post post;
  final bool isActive;
  const _CarouselCard({
    required this.post,
    this.isActive = false,
  });

  @override
  State<_CarouselCard> createState() => _CarouselCardState();
}

class _CarouselCardState extends State<_CarouselCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ken;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _ken = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final title = post.title;
    final img = post.fullImage ?? post.image ?? '';
    final cat = post.category;
    final link = post.link;
    final date = pTimeAgo(post);
    final excerpt = post.excerpt.length > 70
        ? '${post.excerpt.substring(0, 70)}...'
        : post.excerpt;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        openUrl(context, link, post: post);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 400),
        scale: widget.isActive ? 1.0 : 0.95,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: widget.isActive ? 1.0 : 0.7,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                      widget.isActive ? 0.30 : 0.12),
                  blurRadius: widget.isActive ? 30 : 18,
                  offset: Offset(0, widget.isActive ? 12 : 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (img.isNotEmpty)
                    AnimatedBuilder(
                      animation: _ken,
                      builder: (context, _) {
                        return Transform.scale(
                          scale: _ken.value,
                          child: CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            memCacheWidth: 1080,
                            memCacheHeight: 720,
                            placeholder: (_, __) =>
                                Container(color: pnl2),
                            errorWidget: (_, __, ___) => Container(
                              color: pnl2,
                              child: Icon(Icons.article_rounded,
                                  color: accentNotifier.value,
                                  size: 60),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: pnl2,
                      child: Icon(Icons.article_rounded,
                          color: accentNotifier.value, size: 60),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.95),
                        ],
                        stops: const [0.0, 0.35, 0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kPrimaryNavy,
                            kAccentGold,
                            kAccentGoldLight,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 14,
                    child: Row(
                      children: [
                        if (cat.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    kAccentGold,
                                    kAccentGoldDark,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                cat,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  color: Colors.white70, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.5,
                            fontFamily: 'Vazirmatn',
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 12,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        if (excerpt.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            excerpt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 11,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                kAccentGold,
                                kAccentGoldDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'مطالعه کامل',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              SizedBox(width: 5),
                              Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- AD BANNER WIDGET ----------

class AdBannerWidget extends ConsumerWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ad = ref.watch(adBannerProvider);
    if (ad == null || ad.isEmpty) return const SizedBox.shrink();

    final isDark = darkModeNotifier.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: GestureDetector(
        onTap: ad.link.isEmpty
            ? null
            : () {
                HapticFeedback.selectionClick();
                openExternalUrl(ad.link);
              },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? [kDarkCard, kDarkCard2]
                  : [Colors.white, kLightCard2],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: kAccentGold.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (ad.imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: ad.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    memCacheWidth: 1080,
                    placeholder: (_, __) =>
                        Container(height: 160, color: pnl2),
                    errorWidget: (_, __, ___) => Container(
                      height: 160,
                      color: pnl2,
                      child: Icon(Icons.image_not_supported_rounded,
                          color: mutC, size: 40),
                    ),
                  ),
                if (ad.title.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(
                        ad.imageUrl.isEmpty ? 16 : 14),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kAccentGold, kPrimaryNavy],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ad.title,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: txtC,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              height: 1.6,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                        if (ad.link.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: kAccentGold,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- MODERN NEWS BANNER (3 Cards) ----------

class ModernNewsBanner extends ConsumerWidget {
  const ModernNewsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return newsAsync.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final items = list.take(3).toList();

        return Container(
          margin: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 26,
                      decoration: BoxDecoration(
                        color: kNewsRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.circle,
                        color: kNewsRed, size: 8),
                    const SizedBox(width: 8),
                    Text(
                      'اخبار فوری',
                      style: TextStyle(
                        color: txtC,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...items.map((news) => ModernUrgentNewsCard(
                    news: news.toLegacy(),
                  )),
              if (list.length > 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UrgentNewsListPage(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 11),
                        decoration: BoxDecoration(
                          color: kNewsRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: kNewsRed.withOpacity(0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مشاهده همه اخبار فوری',
                              style: TextStyle(
                                color: kNewsRed,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_back_ios_new_rounded,
                                color: kNewsRed, size: 11),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ---------- FOLLOWED CATEGORIES SECTION ----------

class FollowedCategoriesSection extends ConsumerWidget {
  const FollowedCategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(followedCategoriesProvider);
    if (followed.isEmpty) return const SizedBox.shrink();

    final postsState = ref.watch(postsProvider);
    final filtered = postsState.posts
        .where((post) =>
            cats.any((cat) =>
                cat.n == post.category && followed.contains(cat.s)))
        .take(5)
        .toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimaryNavy, kAccentGold],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.favorite_rounded,
                    color: kUrgent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'مطالب موردعلاقه شما',
                  style: TextStyle(
                    color: txtC,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const FollowedCategoriesPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: kPrimaryNavy.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'مدیریت',
                      style: TextStyle(
                        color: kPrimaryNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...filtered.map((post) => Padding(
                padding:
                    const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: ModernPostCard(post: post),
              )),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION H: URGENT NEWS LIST PAGE
// ============================================================

class UrgentNewsListPage extends ConsumerStatefulWidget {
  const UrgentNewsListPage({super.key});
  @override
  ConsumerState<UrgentNewsListPage> createState() =>
      _UrgentNewsListPageState();
}

class _UrgentNewsListPageState
    extends ConsumerState<UrgentNewsListPage> {
  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: kNewsRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.circle, color: kNewsRed, size: 10),
              const SizedBox(width: 8),
              Text(
                'اخبار فوری',
                style: TextStyle(
                  color: txtC,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
        ),
        body: newsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const EmptyWidget(
                  text: 'هنوز خبری منتشر نشده است.');
            }
            return RefreshIndicator(
              color: kNewsRed,
              backgroundColor: pnl,
              onRefresh: () async {
                ref.invalidate(newsProvider);
                await ref.read(newsProvider.future);
              },
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    0, 14, 0, bottomInset + 100),
                itemCount: list.length,
                itemBuilder: (c, i) => ModernUrgentNewsCard(
                  news: list[i].toLegacy(),
                ),
              ),
            );
          },
          loading: () => const NewsSkeleton(),
          error: (e, _) => ErrorBox(
            message: 'خطا: $e',
            onRetry: () => ref.invalidate(newsProvider),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION I: BMI CALCULATOR PAGE (FULL)
// ============================================================

class BMICalculatorPage extends StatefulWidget {
  const BMICalculatorPage({super.key});
  @override
  State<BMICalculatorPage> createState() => _BMICalculatorPageState();
}

class _BMICalculatorPageState extends State<BMICalculatorPage> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'moderate';

  double? _bmi;
  String _bmiCategory = '';
  Color _bmiColor = kSuccess;
  int? _bmr;
  int? _tdee;
  int? _idealWeightMin;
  int? _idealWeightMax;
  bool _hasCalculated = false;

  final List<Map<String, dynamic>> _activityLevels = [
    {
      'key': 'sedentary',
      'label': 'کم‌تحرک',
      'mult': 1.2,
      'desc': 'بدون ورزش'
    },
    {
      'key': 'light',
      'label': 'سبک',
      'mult': 1.375,
      'desc': '۱-۳ روز در هفته'
    },
    {
      'key': 'moderate',
      'label': 'متوسط',
      'mult': 1.55,
      'desc': '۳-۵ روز در هفته'
    },
    {
      'key': 'active',
      'label': 'فعال',
      'mult': 1.725,
      'desc': '۶-۷ روز در هفته'
    },
    {
      'key': 'veryActive',
      'label': 'خیلی فعال',
      'mult': 1.9,
      'desc': 'ورزشکار حرفه‌ای'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _heightCtrl.text = prefs.getString('bmi_height') ?? '';
      _weightCtrl.text = prefs.getString('bmi_weight') ?? '';
      _ageCtrl.text = prefs.getString('bmi_age') ?? '';
      _gender = prefs.getString('bmi_gender') ?? 'male';
      _activityLevel = prefs.getString('bmi_activity') ?? 'moderate';
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bmi_height', _heightCtrl.text);
      await prefs.setString('bmi_weight', _weightCtrl.text);
      await prefs.setString('bmi_age', _ageCtrl.text);
      await prefs.setString('bmi_gender', _gender);
      await prefs.setString('bmi_activity', _activityLevel);
    } catch (_) {}
  }

  void _calculate({bool fromButton = false}) {
    final height = double.tryParse(_heightCtrl.text) ?? 0;
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    final age = int.tryParse(_ageCtrl.text) ?? 0;

    if (height < 50 || weight < 10 || age < 5) {
      setState(() {
        _bmi = null;
        _bmr = null;
        _tdee = null;
        _hasCalculated = false;
      });
      return;
    }

    if (fromButton) {
      setState(() => _hasCalculated = true);
    } else if (!_hasCalculated) {
      return;
    }

    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);

    String category;
    Color color;
    if (bmi < 18.5) {
      category = 'کم‌وزن';
      color = const Color(0xff3b82f6);
    } else if (bmi < 25) {
      category = 'وزن نرمال';
      color = kSuccess;
    } else if (bmi < 30) {
      category = 'اضافه وزن';
      color = kWarning;
    } else if (bmi < 35) {
      category = 'چاقی درجه ۱';
      color = const Color(0xffea580c);
    } else if (bmi < 40) {
      category = 'چاقی درجه ۲';
      color = kUrgent;
    } else {
      category = 'چاقی مفرط';
      color = kUrgentDark;
    }

    int bmr;
    if (_gender == 'male') {
      bmr = (10 * weight + 6.25 * height - 5 * age + 5).round();
    } else {
      bmr = (10 * weight + 6.25 * height - 5 * age - 161).round();
    }

    final mult = _activityLevels.firstWhere(
      (a) => a['key'] == _activityLevel,
      orElse: () => _activityLevels[2],
    )['mult'] as double;
    final tdee = (bmr * mult).round();

    final idealMin = (18.5 * heightM * heightM).round();
    final idealMax = (24.9 * heightM * heightM).round();

    setState(() {
      _bmi = bmi;
      _bmiCategory = category;
      _bmiColor = color;
      _bmr = bmr;
      _tdee = tdee;
      _idealWeightMin = idealMin;
      _idealWeightMax = idealMax;
    });

    _save();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kTabShop, kAccentGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calculate_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'ماشین‌حساب تناسب اندام',
                style: TextStyle(
                  color: txtC,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputSection(),
              const SizedBox(height: 16),
              if (_hasCalculated && _bmi != null) ...[
                _buildBMIResult(),
                const SizedBox(height: 14),
                _buildCalorieResult(),
                const SizedBox(height: 14),
                _buildIdealWeight(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kTabShop, kAccentGold],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.person_rounded, color: kTabShop, size: 18),
              const SizedBox(width: 6),
              Text(
                'اطلاعات شما',
                style: TextStyle(
                  color: txtC,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _genderBtn(
                  label: 'آقا',
                  icon: Icons.male_rounded,
                  value: 'male',
                  color: const Color(0xff2563eb),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _genderBtn(
                  label: 'خانم',
                  icon: Icons.female_rounded,
                  value: 'female',
                  color: const Color(0xffec4899),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _inputField(
                  controller: _heightCtrl,
                  label: 'قد',
                  suffix: 'cm',
                  icon: Icons.straighten_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inputField(
                  controller: _weightCtrl,
                  label: 'وزن',
                  suffix: 'kg',
                  icon: Icons.monitor_weight_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _inputField(
            controller: _ageCtrl,
            label: 'سن',
            suffix: 'سال',
            icon: Icons.cake_rounded,
          ),
          const SizedBox(height: 18),
          Text(
            'سطح فعالیت',
            style: TextStyle(
              color: txtC,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 10),
          ..._activityLevels
              .map((level) => _activityOption(level))
              .toList(),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _calculate(fromButton: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kTabShop,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.calculate_rounded, size: 20),
              label: const Text(
                'محاسبه',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderBtn({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _gender = value);
        if (_hasCalculated) _calculate();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : pnl2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : lineC,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? Colors.white : color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : txtC,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: pnl2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineC),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: kTabShop, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              onChanged: (_) {
                if (_hasCalculated) _calculate();
              },
              style: TextStyle(
                color: txtC,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: mutC,
                  fontSize: 12,
                  fontFamily: 'Vazirmatn',
                ),
                suffixText: suffix,
                suffixStyle: TextStyle(
                  color: mutC,
                  fontSize: 11,
                  fontFamily: 'Vazirmatn',
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityOption(Map<String, dynamic> level) {
    final selected = _activityLevel == level['key'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activityLevel = level['key'] as String);
          if (_hasCalculated) _calculate();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? kTabShop.withOpacity(0.1)
                : pnl2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? kTabShop : lineC,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? kTabShop : Colors.transparent,
                  border: Border.all(
                    color: selected ? kTabShop : mutC,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level['label'] as String,
                      style: TextStyle(
                        color: txtC,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    Text(
                      level['desc'] as String,
                      style: TextStyle(
                        color: mutC,
                        fontSize: 10.5,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '×${level['mult']}',
                style: TextStyle(
                  color: selected ? kTabShop : mutC,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBMIResult() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bmiColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _bmiColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _bmiColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.monitor_weight_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شاخص توده بدنی (BMI)',
                      style: TextStyle(
                        color: txtC,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    Text(
                      _bmiCategory,
                      style: TextStyle(
                        color: _bmiColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _bmi!.toStringAsFixed(1),
                style: TextStyle(
                  color: _bmiColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [
                  Color(0xff3b82f6),
                  Color(0xff059669),
                  Color(0xffd97706),
                  Color(0xffea580c),
                  Color(0xffc1121f),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['کم‌وزن', 'نرمال', 'اضافه', 'چاق']
                .map((t) => Text(
                      t,
                      style: TextStyle(
                        color: mutC,
                        fontSize: 9.5,
                        fontFamily: 'Vazirmatn',
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieResult() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kTabShop.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: kTabShop.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kTabShop,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'کالری مورد نیاز روزانه',
                      style: TextStyle(
                        color: txtC,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    Text(
                      'بر اساس سطح فعالیت',
                      style: TextStyle(
                        color: mutC,
                        fontSize: 10.5,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$_tdee',
                style: const TextStyle(
                  color: kTabShop,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'کالری',
                style: TextStyle(
                  color: kTabShop,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pnl2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: kTabShop, size: 18),
                const SizedBox(width: 8),
                Text(
                  'BMR (سوخت‌وساز پایه):',
                  style: TextStyle(
                    color: mutC,
                    fontSize: 11,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const Spacer(),
                Text(
                  '$_bmr کالری',
                  style: TextStyle(
                    color: txtC,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _calorieGoal(
                  label: 'کاهش',
                  value: _tdee! - 500,
                  color: kSuccess,
                  icon: Icons.trending_down_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _calorieGoal(
                  label: 'تثبیت',
                  value: _tdee!,
                  color: kTabShop,
                  icon: Icons.balance_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _calorieGoal(
                  label: 'افزایش',
                  value: _tdee! + 500,
                  color: const Color(0xff2563eb),
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calorieGoal({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFamily: 'Vazirmatn',
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdealWeight() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineC),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kSuccess,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وزن ایده‌آل شما',
                  style: TextStyle(
                    color: txtC,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                Text(
                  'بر اساس BMI نرمال (18.5 - 24.9)',
                  style: TextStyle(
                    color: mutC,
                    fontSize: 10.5,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$_idealWeightMin - $_idealWeightMax',
            style: const TextStyle(
              color: kSuccess,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'kg',
            style: TextStyle(
              color: kSuccess,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION J: CATEGORY CHIPS BAR
// ============================================================

class CategoryChipsBar extends ConsumerWidget {
  const CategoryChipsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(followedCategoriesProvider);
    final followedCats =
        cats.where((cat) => followed.contains(cat.s)).toList();

    const actionCount = 5;
    final total = 1 + followedCats.length + actionCount;

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      height: R.w(44),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: total,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (c, i) {
          // ---------- ۰) دسته‌های من ----------
          if (i == 0) {
            final count = followed.length;
            final hasItems = count > 0;
            final isDark = darkModeNotifier.value;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FollowedCategoriesPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: hasItems
                      ? const LinearGradient(
                          colors: [kPrimaryNavy, kAccentGold])
                      : null,
                  color: hasItems
                      ? null
                      : (isDark ? kDarkCard2 : kLightCard),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: hasItems
                        ? kAccentGold.withOpacity(0.6)
                        : (isDark ? kDarkBorder : kLightBorder),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasItems
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: hasItems
                          ? Colors.white
                          : (isDark ? txtC : kPrimaryNavy),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'دسته‌های من',
                      style: TextStyle(
                        color: hasItems ? Colors.white : txtC,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                    if (hasItems) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          final idx = i - 1;

          // ---------- ۱) دسته‌های دنبال‌شده ----------
          if (idx < followedCats.length) {
            final cat = followedCats[idx];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryPostsPage(c: cat),
                  ),
                );
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                ref
                    .read(followedCategoriesProvider.notifier)
                    .toggle(cat.s);
                showSnack(context, 'لغو دنبال کردن «${cat.n}»');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cat.c, cat.c.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.i, color: Colors.white, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      cat.n.length > 18
                          ? '${cat.n.substring(0, 16)}...'
                          : cat.n,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final actionIndex = idx - followedCats.length;

          // ---------- ۲) کوئیز ورزشی ----------
          if (actionIndex == 0) {
            return _actionChip(
              icon: Icons.quiz_rounded,
              label: 'کوئیز ورزشی',
              color: kQuizColor,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const QuizPage()),
                );
              },
            );
          }

          // ---------- ۳) تناسب اندام ----------
          if (actionIndex == 1) {
            return _actionChip(
              icon: Icons.calculate_rounded,
              label: 'تناسب اندام',
              color: kTabShop,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BMICalculatorPage()),
                );
              },
            );
          }

          // ---------- ۴) لغات تخصصی ----------
          if (actionIndex == 2) {
            return _actionChip(
              icon: Icons.translate_rounded,
              label: 'لغات تخصصی',
              color: const Color(0xff0f766e),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SportsGlossaryPage()),
                );
              },
            );
          }

          // ---------- ۵) آمار مطالعه ----------
          if (actionIndex == 3) {
            return _actionChip(
              icon: Icons.insights_rounded,
              label: 'آمار مطالعه',
              color: kSuccess,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ReadingStatsPage()),
                );
              },
            );
          }

          // ---------- ۶) نشان‌شده‌ها ----------
          return _actionChip(
            icon: Icons.bookmark_rounded,
            label: 'نشان‌شده‌ها',
            color: kAccentGold,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BookmarksPage()),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: pnl,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: color.withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION K: SPORTS GLOSSARY PAGE (FULL)
// ============================================================

class SportsGlossaryPage extends ConsumerStatefulWidget {
  const SportsGlossaryPage({super.key});
  @override
  ConsumerState<SportsGlossaryPage> createState() =>
      _SportsGlossaryPageState();
}

class _SportsGlossaryPageState
    extends ConsumerState<SportsGlossaryPage>
    with WidgetsBindingObserver {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _refreshing = false;
  bool _isFetching = false;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
    _autoRefresh = Timer.periodic(const Duration(seconds: 30), (t) {
      if (mounted && !_refreshing && !_isFetching) _silentRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _silentRefresh();
    }
  }

  Future<void> _silentRefresh() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      await ref.read(glossaryRepoProvider).getAll(force: true);
      if (mounted) ref.invalidate(glossaryProvider);
    } catch (_) {} finally {
      _isFetching = false;
    }
  }

  Future<void> _manualRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _refreshing = true);
    await _silentRefresh();
    if (mounted) {
      setState(() => _refreshing = false);
      showSnack(context, 'لغات به‌روز شد ✅');
    }
  }

  @override
  Widget build(BuildContext context) {
    final glossaryAsync = ref.watch(glossaryProvider);

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: bgC,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff0f766e), Color(0xff14b8a6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.translate_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'لغات تخصصی',
                style: TextStyle(
                  color: txtC,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          backgroundColor: bgC,
          foregroundColor: txtC,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _refreshing ? null : _manualRefresh,
              icon: _refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xff0f766e)),
                    )
                  : const Icon(Icons.refresh_rounded,
                      color: Color(0xff0f766e), size: 22),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              decoration: BoxDecoration(
                color: pnl,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: lineC),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(
                  color: txtC,
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'جستجو در لغات...',
                  hintStyle:
                      TextStyle(color: mutC, fontFamily: 'Vazirmatn'),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xff0f766e)),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: mutC, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Count
            glossaryAsync.valueOrNull != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xff0f766e)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_filtered(glossaryAsync.valueOrNull!).length} لغت',
                            style: const TextStyle(
                              color: Color(0xff0f766e),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'به‌روزرسانی خودکار: ۳۰ ثانیه',
                          style: TextStyle(
                            color: mutC,
                            fontSize: 10,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 10),
            Expanded(
              child: glossaryAsync.when(
                data: (words) {
                  final filtered = _filtered(words);

                  if (filtered.isEmpty) {
                    return EmptyWidget(
                      text: _query.isEmpty
                          ? 'لغتی ثبت نشده'
                          : 'نتیجه‌ای پیدا نشد',
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xff0f766e),
                    backgroundColor: pnl,
                    onRefresh: _manualRefresh,
                    child: ListView.separated(
                      physics:
                          const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                          14, 0, 14, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (c, i) =>
                          _buildCard(filtered[i]),
                    ),
                  );
                },
                loading: () => const ArticlesSkeleton(),
                error: (e, _) => ErrorBox(
                  message: 'خطا: $e',
                  onRetry: () => ref.invalidate(glossaryProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<GlossaryWord> _filtered(List<GlossaryWord> words) {
    if (_query.isEmpty) return words;
    return words
        .where((w) =>
            w.en.toLowerCase().contains(_query) ||
            w.fa.contains(_query) ||
            w.desc.contains(_query))
        .toList();
  }

  Widget _buildCard(GlossaryWord word) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pnl,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineC),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0f766e).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xff0f766e).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  word.en,
                  style: const TextStyle(
                    color: Color(0xff0f766e),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  word.fa,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: txtC,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
          if (word.desc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pnl2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                word.desc,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: mutC,
                  fontSize: 12,
                  height: 1.7,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
