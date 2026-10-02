import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ProjectGroup } from '../models/ProjectGroup';
import { User } from '../models/User';
import { Invitation } from '../models/Invitation';

export const getGroups = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const { searchQuery } = req.query;

    const currentUser = await User.findById(userId);
    const userEmail = currentUser?.email ? currentUser.email.toLowerCase() : '';

    let query: any = {
      $or: [
        { ownerId: userId },
        { 'members.userId': userId },
        { 'members.email': userEmail },
      ],
    };

    if (searchQuery && typeof searchQuery === 'string') {
      query.name = { $regex: searchQuery, $options: 'i' };
    }

    const groups = await ProjectGroup.find(query)
      .populate('ownerId', 'name email')
      .populate('members.userId', 'name email')
      .sort({ updatedAt: -1 });

    res.status(200).json({ success: true, count: groups.length, groups });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createGroup = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const { name, description, icon, isPrimary } = req.body;

    if (!name) {
      res.status(400).json({ success: false, message: 'Group name is required' });
      return;
    }

    const currentUser = await User.findById(userId);

    const group = await ProjectGroup.create({
      ownerId: userId,
      name,
      description: description || '',
      icon: icon || 'construction',
      isPrimary: isPrimary || false,
      members: [
        {
          email: (currentUser?.email || `user_${userId}@spendhike.app`).toLowerCase(),
          name: currentUser?.name || 'Admin',
          userId,
          role: 'Admin',
        },
      ],
    });

    res.status(201).json({ success: true, message: 'Project group created successfully', group });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getGroupById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const group = await ProjectGroup.findById(id)
      .populate('ownerId', 'name email')
      .populate('members.userId', 'name email mobile');

    if (!group) {
      res.status(404).json({ success: false, message: 'Project group not found' });
      return;
    }

    res.status(200).json({ success: true, group });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const addMember = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const { id } = req.params;
    const { email, query, role } = req.body;
    const searchParam = (email || query || '').trim();

    if (!searchParam) {
      res.status(400).json({ success: false, message: 'Member email is required' });
      return;
    }

    const targetEmail = searchParam.toLowerCase();

    const group = await ProjectGroup.findById(id);
    if (!group) {
      res.status(404).json({ success: false, message: 'Project group not found' });
      return;
    }

    const targetUser = await User.findOne({
      $or: [
        { email: targetEmail },
        { mobile: searchParam },
        { name: { $regex: searchParam, $options: 'i' } }
      ]
    });

    const alreadyMember = group.members.some(
      (m) => m.email.toLowerCase() === targetEmail || (targetUser && m.userId && m.userId.toString() === targetUser._id.toString())
    );

    if (alreadyMember) {
      res.status(409).json({ success: false, message: `User with email ${targetEmail} is already a member of this group` });
      return;
    }

    const invitationCode = `INV-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

    // Create pending invitation for recipient to receive in-app notification
    const existingInvite = await Invitation.findOne({
      groupId: id,
      status: 'PENDING',
      $or: [
        { recipientEmailOrPhone: targetEmail },
        ...(targetUser ? [{ recipientUserId: targetUser._id }] : [])
      ]
    });

    if (!existingInvite) {
      await Invitation.create({
        groupId: id,
        invitedBy: userId,
        recipientEmailOrPhone: targetUser ? targetUser.email.toLowerCase() : targetEmail,
        recipientUserId: targetUser ? targetUser._id : undefined,
        role: role || 'Editor',
        status: 'PENDING',
        invitationCode,
      });
    }

    res.status(200).json({
      success: true,
      message: `Invitation notification sent to ${targetUser ? targetUser.name : targetEmail}! They can accept to join.`,
      member: {
        email: targetUser ? targetUser.email : targetEmail,
        name: targetUser ? targetUser.name : targetEmail.split('@')[0],
        role: role || 'Editor',
      },
      group,
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getMembers = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const group = await ProjectGroup.findById(id).populate('members.userId', 'name email mobile');

    if (!group) {
      res.status(404).json({ success: false, message: 'Project group not found' });
      return;
    }

    res.status(200).json({ success: true, members: group.members });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const removeMember = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id, memberId } = req.params;
    const group = await ProjectGroup.findById(id);

    if (!group) {
      res.status(404).json({ success: false, message: 'Project group not found' });
      return;
    }

    const rawMemberId = (Array.isArray(memberId) ? memberId[0] : memberId) || '';
    const cleanMemberId = decodeURIComponent(rawMemberId).toLowerCase().trim();

    group.members = group.members.filter(
      (m: any) =>
        m._id?.toString() !== rawMemberId &&
        m.userId?.toString() !== rawMemberId &&
        m.email.toLowerCase().trim() !== cleanMemberId &&
        m.name.toLowerCase().trim() !== cleanMemberId
    );
    await group.save();

    res.status(200).json({
      success: true,
      message: 'Member removed from group successfully',
      group,
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};
