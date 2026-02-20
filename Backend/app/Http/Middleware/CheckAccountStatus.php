<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * CheckAccountStatus
 *
 * Blocks all protected routes if the account's status is not "Active".
 * Reads the `status` column directly from the DB-loaded user model.
 *
 * Alias: 'status' (registered in bootstrap/app.php)
 */
class CheckAccountStatus
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized.',
            ], 401);
        }

        if (strtolower($user->status ?? '') !== 'active') {
            return response()->json([
                'success' => false,
                'message' => 'Your account is '
                    . ucfirst(strtolower($user->status ?: 'inactive'))
                    . '. Please contact the university administration.',
            ], 403);
        }

        return $next($request);
    }
}
