<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        if (!method_exists($user, 'hasRole')) {
             return response()->json(['success' => false, 'message' => 'Forbidden'], 403);
        }

        foreach ($roles as $roleGroup) {
            $individualRoles = explode(',', $roleGroup);
            foreach ($individualRoles as $role) {
                if ($user->hasRole(trim($role))) {
                    return $next($request);
                }
            }
        }

        return response()->json([
            'success' => false, 
            'message' => 'Forbidden: You do not have the required role'
        ], 403);
    }
}
