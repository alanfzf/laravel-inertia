<?php

use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;
use Inertia\Inertia;


Route::middleware(['auth'])->get('/', function () {
    return Inertia::render('hello');
});

Route::prefix('auth')->group(function () {

    Route::get('/login', [AuthController::class, 'login'])
        ->name('login');

    Route::post('/login', [AuthController::class, 'authenticate'])
        ->name('auth.login');

    Route::get('/logout', [AuthController::class, 'logout'])
        ->name('auth.logout');
});
