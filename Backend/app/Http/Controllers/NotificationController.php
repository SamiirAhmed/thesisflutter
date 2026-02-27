<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    /**
     * Get recent notifications for the authenticated user.
     */
    public function getMyNotifications(Request $request)
    {
        $userId = $request->header('X-USER-ID');

        if (!$userId) {
            return response()->json([
                'success' => false,
                'message' => 'User ID missing in headers.'
            ], 400);
        }

        $notifications = DB::table('notifications')
            ->where('receiver_user_id', $userId)
            ->where('status', 'ACTIVE')
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get();

        return response()->json([
            'success' => true,
            'notifications' => $notifications
        ]);
    }

    /**
     * Mark a notification as read.
     */
    public function markAsRead(Request $request, $id)
    {
        DB::table('notifications')
            ->where('not_no', $id)
            ->update([
                'is_read' => 1,
                'read_at' => now(),
                'updated_at' => now()
            ]);

        return response()->json([
            'success' => true,
            'message' => 'Notification marked as read.'
        ]);
    }
}
