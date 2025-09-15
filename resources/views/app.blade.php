<!DOCTYPE html>
<html lang="en" translate="no">
<head>
    <meta charset="UTF-8">
    <meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport" />
    <meta content="true" name="HandheldFriendly" />
    <title>{{ config('app.name') }}</title>
    @routes
    @viteReactRefresh
    @vite(['resources/js/app.jsx', 'resources/css/app.css'])
    @inertiaHead
</head>
<body>
    <noscript>
        <strong>
            We're sorry but this application doesn't work properly without JavaScript enabled. Please enable it to
            continue.
        </strong>
    </noscript>
    @inertia
</body>
</html>
