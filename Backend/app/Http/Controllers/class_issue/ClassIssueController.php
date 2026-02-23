<?php

namespace App\Http\Controllers\class_issue;

use App\Http\Controllers\Controller;
use App\Models\class_issue\ClassIssue;
use App\Models\class_issue\ClassIssueComplaint;
use App\Models\class_issue\ClassIssueTracking;
use App\Models\ClassLeader;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ClassIssueController extends Controller
{
    /**
     * Get allowed categories (from categories table).
     */
    public function getIssueTypes()
    {
        $categories = DB::table('categories')->select('cat_no', 'cat_name')->get();
        return response()->json([
            'success' => true,
            'data' => $categories
        ]);
    }

    /**
     * Submit a classroom issue (Class Leader only).
     */
    public function submitIssue(Request $request)
    {
        $user = Auth::user();

        // 1. Security Check: Must be a Class Leader
        $leader = $user->getLeaderRecord();
        if (!$leader) {
            return response()->json([
                'success' => false,
                'message' => 'Only Class Leaders are allowed to submit classroom issues.'
            ], 403);
        }

        // 2. Validation
        $request->validate([
            'cat_no' => 'required|exists:categories,cat_no',
            'description' => 'required|string|max:1000',
        ]);

        try {
            DB::beginTransaction();

            // 3. Find or Create a ClassIssue entry for this category 
            // to satisfy the foreign key in class_issues_complaints
            $category = DB::table('categories')->where('cat_no', $request->cat_no)->first();
            
            $issue = ClassIssue::firstOrCreate(
                ['cat_no' => $request->cat_no],
                ['issue_name' => $category->cat_name]
            );

            // 4. Create Complaint
            $complaint = ClassIssueComplaint::create([
                'cl_issue_id' => $issue->cl_issue_id,
                'description' => $request->description,
                'lead_id'     => $leader->lead_id,
            ]);

            // 5. Initial Tracking Record (Pending)
            ClassIssueTracking::create([
                'cl_is_co_no'        => $complaint->cl_is_co_no,
                'new_status'         => 'Pending',
                'changed_by_user_id' => $user->user_id,
                'note'               => 'Issue submitted by Class Leader.',
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Classroom issue submitted successfully.',
                'data' => $complaint
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to submit issue: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get issues related to the student's class.
     * If Normal Student: Show issues submitted by their Class Leader.
     * If Class Leader: Show issues they submitted.
     */
    public function getMyClassIssues()
    {
        $user = Auth::user();
        $student = $user->student;

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Student record not found.'
            ], 404);
        }

        // Find the class(es) the student is in
        $classIds = DB::table('studet_classes')
            ->where('std_id', $student->std_id)
            ->pluck('cls_no');

        // Find the leaders of those classes
        $leaderIds = ClassLeader::whereIn('cls_no', $classIds)->pluck('lead_id');

        // Fetch complaints from those leaders
        $issues = ClassIssueComplaint::with(['issue', 'leader.classroom'])
            ->whereIn('lead_id', $leaderIds)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($complaint) {
                // Get latest status from tracking
                $latestStatus = ClassIssueTracking::where('cl_is_co_no', $complaint->cl_is_co_no)
                    ->orderBy('created_at', 'desc')
                    ->first();

                return [
                    'id'          => $complaint->cl_is_co_no,
                    'issue_name'  => $complaint->issue->issue_name ?? 'Unknown',
                    'description' => $complaint->description,
                    'status'      => $latestStatus->new_status ?? 'Pending',
                    'class_name'  => $complaint->leader->classroom->cl_name ?? 'N/A',
                    'submitted_at'=> $complaint->created_at->toDateTimeString(),
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $issues
        ]);
    }

    /**
     * Get tracking history for a specific issue.
     */
    public function getIssueTracking($id)
    {
        $tracking = ClassIssueTracking::where('cl_is_co_no', $id)
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $tracking
        ]);
    }
}
