# صحبة — Sohba

> رفيقك على طريق الطاعة

تطبيق إسلامي يحوّل الصلاة والذكر إلى رحلة إنجاز يومية فيها حسنات وإيمان ومواصلة وميداليات — مع مجموعة تنافسية بين الإخوان.

## المعمارية

- **Flutter** (Dart 3.11+)
- **Supabase** — Auth + Postgres + RLS + Realtime
- **adhan** — حساب مواقيت الصلاة (طريقة مصرية + شافعي)
- **Provider** — State management
- **Hisnul Muslim** — قاعدة بيانات الأذكار (JSON)

## الميزات

- ✅ تسجيل صلاة (جماعة / منفرد / قضاء / فائتة) بتوقيتات دقيقة
- ✅ نظام حسنات + إيمان (100 حسنة = 1 إيمان)
- ✅ سيئات قابلة للتوبة (200 سيئة = -4 إيمان)
- ✅ Streak + مضاعفات (7 أيام +10%, 30 يوم +25%, ...)
- ✅ ميداليات (12 ميدالية عبر 4 فئات)
- ✅ مجموعات + كود دعوة + Leaderboard realtime
- ✅ أذكار الصباح/المساء من حصن المسلم
- ✅ إشعارات + Settings

## الإعداد

### 1. المتطلبات
- Flutter SDK ^3.11
- Node.js 18+ (لـ Supabase CLI — اختياري)

### 2. Supabase

1. أنشئ مشروع على [supabase.com](https://supabase.com)
2. افتح SQL Editor ونفّذ:
   - `supabase/migrations/001_initial_schema.sql`
3. انسخ URL + anon key من Settings → API

### 3. الإعدادات المحلية

```bash
cp .env.example .env
# عدّل .env بـ URL والـ key الحقيقي
flutter pub get