<?php

namespace App\Http\Controllers\campus_env;

use App\Http\Controllers\Controller;
use App\Models\campus_env\CampusEnvironment;
use App\Models\campus_env\CampusEnvComplaint;
use App\Models\campus_env\CampusEnvAssign;
use App\Models\campus_env\CampusEnvTracking;
use App\Models\campus_env\CampusEnvSupport;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class CampusEnvController extends Controller
{
    /**
     * Get all campus environment issue types.
     */
    public function getIssueTypes()
    {
        $issues = DB::table('campus_enviroment')
            ->select('camp_env_no', 'campuses_issues')
            ->orderBy('campuses_issues')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $issues,
        ]);
    }

    /**
     * Submit a new campus environment complaint.
     * Bypasses finfo requirement by manually handling extensions.
     */
    public function submitComplaint(Request $request)
    {
        // Notice: 'file' instead of 'image' to bypass finfo MIME detection
        $request->validate([
            'camp_env_no' => 'required|integer',
            'title'       => 'nullable|string|max:255',
            'description' => 'required|string',
            'images'      => 'nullable|array|max:5',
            'images.*'    => 'file|max:10240', // Increase to 10MB
        ]);

        $user = $request->user();

        // 1. Get student record
        $student = DB::table('students')->where('user_id', $user->user_id)->first();
        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Only students can submit campus environment complaints.',
            ], 403);
        }

        // 2. Handle image uploads (Manual extension handling to avoid finfo)
        $imagePaths = [];
        $allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                // Get extension manually from original name
                $originalName = $image->getClientOriginalName();
                $extension = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));

                if (in_array($extension, $allowedExtensions)) {
                    $filename = uniqid('campus_env_', true) . '.' . $extension;
                    
                    // Use move() instead of store() which sometimes triggers finfo
                    $destinationPath = public_path('storage/campus_env');
                    if (!file_exists($destinationPath)) {
                        mkdir($destinationPath, 0755, true);
                    }
                    
                    $image->move($destinationPath, $filename);
                    $imagePaths[] = 'campus_env/' . $filename;
                }
            }
        }

        // 4. Create complaint + tracking + default faculty assignment in transaction
        try {
            return DB::transaction(function () use ($request, $student, $imagePaths, $user) {
                $campEnvNo = $request->camp_env_no;

                // Resolve "Other" if necessary
                $otherType = DB::table('campus_enviroment')
                    ->where('camp_env_no', $campEnvNo)
                    ->whereRaw("LOWER(campuses_issues) = 'other'")
                    ->first();

                if ($otherType && $request->filled('title')) {
                    $newTitle = trim($request->title);
                    
                    // Check if this title already exists as a category
                    $existingType = DB::table('campus_enviroment')
                        ->whereRaw("LOWER(campuses_issues) = ?", [strtolower($newTitle)])
                        ->first();

                    if ($existingType) {
                        $campEnvNo = $existingType->camp_env_no;
                    } else {
                        // Create new category
                        $newId = DB::table('campus_enviroment')->insertGetId([
                            'campuses_issues' => $newTitle,
                            'cat_no' => $otherType->cat_no,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                        $campEnvNo = $newId;
                    }
                }

                // NOW check if there's an active complaint for this specific resolved category
                $activeComplaint = DB::table('campus_envo_complaints as cec')
                    ->where('cec.camp_env_no', $campEnvNo)
                    ->whereExists(function ($query) {
                        $query->select(DB::raw(1))
                            ->from('campus_env_tracking as cet')
                            ->whereColumn('cet.cmp_env_com_no', 'cec.cmp_env_com_no')
                            ->where('cet.new_status', '!=', 'Resolved')
                            ->orderBy('cet.created_at', 'desc')
                            ->limit(1);
                    })
                    ->first();

                if ($activeComplaint) {
                    // We only block if the resolved category is NOT the generic "Other" anymore
                    // (i.e. if it's Toilet, or a sub-category that was previously created)
                    $isStillOther = DB::table('campus_enviroment')
                        ->where('camp_env_no', $campEnvNo)
                        ->whereRaw("LOWER(campuses_issues) = 'other'")
                        ->exists();

                    if (!$isStillOther) {
                        throw new \Exception('An issue for this category is already being processed. Please support the existing complaint instead.');
                    }
                }

                $complaint = CampusEnvComplaint::create([
                    'camp_env_no'  => $campEnvNo,
                    'title'        => $request->title,
                    'description'  => $request->description,
                    'images'       => !empty($imagePaths) ? json_encode($imagePaths) : null,
                    'std_id'       => $student->std_id,
                ]);

                CampusEnvTracking::create([
                    'cmp_env_com_no'    => $complaint->cmp_env_com_no,
                    'new_status'        => 'Pending',
                    'changed_by_user_id' => $user->user_id,
                    'changed_date'      => now(),
                    'note'              => 'Complaint submitted.',
                ]);

                $facultyUser = DB::table('users as u')
                    ->join('roles as r', 'u.role_id', '=', 'r.role_id')
                    ->whereRaw("LOWER(r.role_name) = 'faculty'")
                    ->where('u.status', 'Active')
                    ->select('u.user_id')
                    ->first();

                if ($facultyUser) {
                    CampusEnvAssign::create([
                        'cmp_env_com_no'     => $complaint->cmp_env_com_no,
                        'assigned_to_user_id' => $facultyUser->user_id,
                        'assigned_date'      => now(),
                        'assigned_status'    => 'Pending',
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'message' => 'Campus environment complaint submitted successfully!',
                ]);
            });
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    public function getComplaints(Request $request)
    {
        $user = $request->user();

        $query = DB::table('campus_envo_complaints as cec')
            ->leftJoin('campus_enviroment as ce', 'cec.camp_env_no', '=', 'ce.camp_env_no')
            ->leftJoin('students as s', 'cec.std_id', '=', 's.std_id')
            ->select(
                'cec.cmp_env_com_no as id',
                'ce.campuses_issues as issue_name',
                'cec.title',
                'cec.description',
                'cec.images',
                's.name as student_name',
                'cec.created_at as submitted_at',
                DB::raw("(SELECT new_status FROM campus_env_tracking WHERE cmp_env_com_no = cec.cmp_env_com_no ORDER BY created_at DESC LIMIT 1) as status"),
                DB::raw("(SELECT COUNT(*) FROM campus_env_support WHERE cmp_env_com_no = cec.cmp_env_com_no) as support_count")
            )
            ->orderBy('cec.created_at', 'desc');

        $complaints = $query->get();

        $studentRecord = DB::table('students')->where('user_id', $user->user_id)->first();
        $supportedIds = [];
        if ($studentRecord) {
            $supportedIds = DB::table('campus_env_support')
                ->where('std_id', $studentRecord->std_id)
                ->pluck('cmp_env_com_no')
                ->toArray();
        }

        foreach ($complaints as $complaint) {
            $complaint->status = $complaint->status ?? 'Pending';
            $complaint->has_supported = in_array($complaint->id, $supportedIds);
            $complaint->images = $complaint->images ? json_decode($complaint->images, true) : [];
        }

        return response()->json([
            'success' => true,
            'data' => $complaints,
        ]);
    }

    public function getTracking(Request $request, $id)
    {
        $tracking = CampusEnvTracking::where('cmp_env_com_no', $id)
            ->orderBy('created_at', 'asc')
            ->get(['cet_no', 'old_status', 'new_status', 'note', 'changed_date', 'created_at']);

        return response()->json([
            'success' => true,
            'data' => $tracking,
        ]);
    }

    public function supportComplaint(Request $request)
    {
        $request->validate([
            'cmp_env_com_no' => 'required|integer|exists:campus_envo_complaints,cmp_env_com_no',
        ]);

        $user = $request->user();
        $student = DB::table('students')->where('user_id', $user->user_id)->first();

        if (!$student) return response()->json(['success' => false, 'message' => 'Only students can support.'], 403);

        $existing = CampusEnvSupport::where('cmp_env_com_no', $request->cmp_env_com_no)
            ->where('std_id', $student->std_id)
            ->first();

        if ($existing) {
            $existing->delete();
            return response()->json(['success' => true, 'message' => 'Removed.', 'supported' => false]);
        }

        CampusEnvSupport::create([
            'cmp_env_com_no' => $request->cmp_env_com_no,
            'std_id'         => $student->std_id,
            'supported_at'   => now(),
        ]);

        return response()->json(['success' => true, 'message' => 'Supported!', 'supported' => true]);
    }

    public function updateStatus(Request $request)
    {
        $request->validate(['id' => 'required|integer', 'status' => 'required|string']);
        $user = $request->user();

        return DB::transaction(function () use ($request, $user) {
            $id = $request->id;
            $newStatus = $request->status;
            
            $currentStatus = CampusEnvTracking::where('cmp_env_com_no', $id)
                ->orderBy('created_at', 'desc')
                ->value('new_status');

            CampusEnvTracking::create([
                'cmp_env_com_no'     => $id,
                'old_status'         => $currentStatus,
                'new_status'         => $newStatus,
                'changed_by_user_id' => $user->user_id,
                'changed_date'       => now(),
                'note'               => $request->note ?? 'Status updated.',
            ]);

            CampusEnvAssign::where('cmp_env_com_no', $id)->update(['assigned_status' => $newStatus]);

            return response()->json(['success' => true, 'message' => 'Updated!']);
        });
    }

    public function getImage(Request $request, $filename)
    {
        $path = 'campus_env/' . $filename;
        if (!Storage::disk('public')->exists($path)) {
            return response()->json(['success' => false, 'message' => 'Image not found.'], 404);
        }
        return response()->file(Storage::disk('public')->path($path));
    }
}
