<?php

namespace App\Http\Controllers\class_issue;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\ClassLeader;
use App\Models\class_issue\ClassIssue;
use App\Models\class_issue\ClassIssueComplaint;
use App\Models\class_issue\ClassIssueTracking;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClassIssueController extends Controller
{
    /**
     * Get all issue types from the class_issues table.
     * Each issue has a default category (cat_no).
     */
    public function getIssueTypes()
    {
        $issues = DB::table('class_issues')
            ->orderBy('issue_name', 'asc')
            ->select('cl_issue_id as cat_no', 'issue_name as cat_name')
            ->get();
        
        return response()->json([
            'success' => true,
            'data' => $issues
        ]);
    }

    /**
     * Get classes where the authenticated user is a leader.
     */
    public function getMyClasses(Request $request)
    {
        $user = $request->user();
        
        $classes = DB::table('leaders as l')
            ->join('students as s', 'l.std_id', '=', 's.std_id')
            ->join('classes as c', 'l.cls_no', '=', 'c.cls_no')
            ->where('s.user_id', $user->user_id)
            ->select('l.cls_no', 'c.cl_name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $classes
        ]);
    }

    /**
     * Submit a new class issue complaint.
     */
    public function submitIssue(Request $request)
    {
        $request->validate([
            'cat_no' => 'required|integer',
            'description' => 'required|string',
            'cls_no' => 'nullable|integer',
        ]);

        $user = $request->user();
        $clIssueId = $request->cat_no;
        $description = $request->description;
        $clsNo = $request->cls_no;

        // 1. Verify user is a leader
        $leaderQuery = DB::table('leaders as l')
            ->join('students as s', 'l.std_id', '=', 's.std_id')
            ->where('s.user_id', $user->user_id);
            
        if ($clsNo) {
            $leaderQuery->where('l.cls_no', $clsNo);
        }

        $leader = $leaderQuery->select('l.lead_id')->first();

        if (!$leader) {
            return response()->json([
                'success' => false,
                'message' => 'User is not a Class Leader for this class.'
            ], 403);
        }

        // 2. Verify the class issue exists
        $classIssue = ClassIssue::find($clIssueId);
        if (!$classIssue) {
            return response()->json([
                'success' => false,
                'message' => 'Issue type not found.'
            ], 404);
        }

        // 3. Create Complaint and Tracking
        return DB::transaction(function () use ($classIssue, $description, $leader, $user) {
            $complaint = ClassIssueComplaint::create([
                'cl_issue_id' => $classIssue->cl_issue_id,
                'description' => $description,
                'lead_id' => $leader->lead_id,
            ]);

            ClassIssueTracking::create([
                'cl_is_co_no' => $complaint->cl_is_co_no,
                'new_status' => 'Pending',
                'changed_by_user_id' => $user->user_id,
                'note' => 'Submitted',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Issue reported successfully!'
            ]);
        });
    }

    /**
     * Get complaints submitted by the leader or all (depending on logic).
     * The legacy script shows ALL complaints from ALL classes.
     */
    public function getMyClassIssues(Request $request)
    {
        $user = $request->user();

        // 1. Get the class(es) the user belongs to (Student/Leader)
        $userClassNos = DB::table('students as s')
            ->join('studet_classes as sc', 's.std_id', '=', 'sc.std_id')
            ->where('s.user_id', $user->user_id)
            ->pluck('sc.cls_no');

        $query = DB::table('class_issues_complaints as cic')
            ->leftJoin('class_issues as ci', 'cic.cl_issue_id', '=', 'ci.cl_issue_id')
            ->leftJoin('categories as c', 'ci.cat_no', '=', 'c.cat_no')
            ->leftJoin('leaders as l', 'cic.lead_id', '=', 'l.lead_id')
            ->leftJoin('classes as cl', 'l.cls_no', '=', 'cl.cls_no')
            ->select(
                'cic.cl_is_co_no as id',
                DB::raw("IFNULL(ci.issue_name, 'Classroom Issue') as issue_name"),
                'cic.description',
                DB::raw("IFNULL(cl.cl_name, 'Unknown Class') as class_name"),
                'cic.created_at as submitted_at',
                DB::raw("(SELECT new_status FROM class_issue_tracking WHERE cl_is_co_no = cic.cl_is_co_no ORDER BY created_at DESC LIMIT 1) as status")
            );

        // 2. Privacy Check: 
        // Admin (5) and ExamOfficer (8) can see all.
        // Students (6) and Teachers (7) follow class-level privacy.
        if (!in_array((int)$user->role_id, [User::ROLE_ADMIN, User::ROLE_EXAM_OFFICER])) {
            if ($userClassNos->isEmpty()) {
                return response()->json(['success' => true, 'data' => []]);
            }
            $query->whereIn('l.cls_no', $userClassNos);
        }

        $issues = $query->orderBy('cic.created_at', 'desc')->get();

        foreach ($issues as $issue) {
            if (!$issue->status) {
                $issue->status = 'Pending';
            }
        }

        return response()->json([
            'success' => true,
            'data' => $issues
        ]);
    }

    /**
     * Get tracking history for a specific complaint.
     */
    public function getIssueTracking(Request $request, $id)
    {
        $user = $request->user();

        // 1. Find the complaint's class
        $complaint = DB::table('class_issues_complaints as cic')
            ->join('leaders as l', 'cic.lead_id', '=', 'l.lead_id')
            ->where('cic.cl_is_co_no', $id)
            ->select('l.cls_no')
            ->first();

        if (!$complaint) {
            return response()->json(['success' => false, 'message' => 'Complaint not found.'], 404);
        }

        // 2. Privacy Check
        if (!in_array((int)$user->role_id, [User::ROLE_ADMIN, User::ROLE_EXAM_OFFICER])) {
            $userClassNos = DB::table('students as s')
                ->join('studet_classes as sc', 's.std_id', '=', 'sc.std_id')
                ->where('s.user_id', $user->user_id)
                ->pluck('sc.cls_no');

            if (!$userClassNos->contains($complaint->cls_no)) {
                return response()->json(['success' => false, 'message' => 'Access denied to this class issue.'], 403);
            }
        }

        $tracking = ClassIssueTracking::where('cl_is_co_no', $id)
            ->orderBy('created_at', 'asc')
            ->get(['cit_no', 'old_status', 'new_status', 'note', 'created_at as changed_date']);

        return response()->json([
            'success' => true,
            'data' => $tracking
        ]);
    }

    /**
     * Update the status of a complaint (Staff/Admin usage).
     */
    public function updateStatus(Request $request)
    {
        $request->validate([
            'id' => 'required|integer',
            'status' => 'required|string',
            'note' => 'nullable|string',
        ]);

        $complaintId = $request->id;
        $newStatus = $request->status;
        $note = $request->note ?? 'Status updated.';
        $user = $request->user();

        return DB::transaction(function () use ($complaintId, $newStatus, $note, $user) {
            // Get current status
            $currentStatus = ClassIssueTracking::where('cl_is_co_no', $complaintId)
                ->orderBy('created_at', 'desc')
                ->value('new_status');

            $tracking = ClassIssueTracking::create([
                'cl_is_co_no' => $complaintId,
                'old_status' => $currentStatus,
                'new_status' => $newStatus,
                'changed_by_user_id' => $user->user_id,
                'note' => $note,
            ]);

            return response()->json([
                'success' => true,
                'message' => "Status updated from " . ($currentStatus ?? 'NULL') . " to $newStatus"
            ]);
        });
    }
}
